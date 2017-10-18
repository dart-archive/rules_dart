"""Common utilities for creating and manipulating dart context providers."""

load(
    "//dart/build_rules/common:constants.bzl",
    "analysis_extension",
    "api_summary_extension",
    "dart_filetypes",
    "ALL_PLATFORMS",
)
load(
    "//dart/build_rules/common:ddc.bzl",
    "compute_ddc_output_dir",
)
load(
    "//dart/build_rules/common:label.bzl",
    "label_to_dart_package_name",
)
load(
    "//dart/build_rules/common:path.bzl",
    "filter_files",
)
load(
    "//dart/build_rules/common:_archive.bzl",
    "create_archive",
)

def collect_dart_context(dart_ctx, transitive = True, include_self = True):
  """Collect direct or transitive deps in a map, merging contexts as needed."""
  dart_ctxs = [dart_ctx]
  if transitive:
    dart_ctxs += [d.dart for d in dart_ctx.transitive_deps.values()]
  else:
    dart_ctxs += [d.dart for d in dart_ctx.deps]

  # Optionally, exclude all self-packages.
  if not include_self:
    dart_ctxs = [c for c in dart_ctxs if c.package != dart_ctx.package]

  # Merge Dart context by package.
  ctx_map = {}
  for dc in dart_ctxs:
    if dc.package in ctx_map:
      dc = _merge_dart_context(ctx_map[dc.package], dc)
    ctx_map[dc.package] = dc
  return ctx_map

def make_dart_context(
    ctx,
    package = None,
    lib_root = None,
    enable_summaries = False,
    enable_analysis = False,
    checks = None,
    srcs = None,
    outline_srcs = None,
    data = None,
    deps = None,
    platforms = ALL_PLATFORMS,
    license_files = []):
  """Creates a dart context for a target.

  Args:
    ctx: The target context.
    package: The dart package name.
    lib_root: The lib folder for the package.
    enable_summaries: Whether to generate analyzer summaries.
    enable_analysis: Whether to generate analyzer output.
    checks: A file for post-processed analyzer output.
    srcs: Source files.
    outline_srcs: Source files with possibly incomplete implementations but full
      api outlines. These are intended for use when generating summaries only.
      Defaults to `srcs` if not provided.
    data: Data files.
    deps: Dart library dependencies.
    license_files: License files associated with the target.

  Returns:
    The dart context; a struct.
  """
  label = ctx.label
  if not package:
    package = label_to_dart_package_name(label)

  if not lib_root:
    lib_root = ""
    if label.workspace_root.startswith("external/"):
      lib_root += label.workspace_root[len("external/"):] + "/"
    if label.package:
      lib_root += label.package + "/"
    lib_root += "lib/"

  srcs = depset(srcs or [])
  outline_srcs = depset(outline_srcs or srcs)
  dart_srcs = filter_files(dart_filetypes, srcs)
  data = depset(data or [])
  deps = deps or []
  archive_srcs = list(srcs)
  platforms = list(platforms)

  for platform in platforms:
    if platform not in ALL_PLATFORMS:
      fail(("Invalid platforms selection for %s. " % label) +
           ("%s is not an available platform. " % platform) +
           ("Should be one of %s" % ALL_PLATFORMS))


  archive = None
  if archive_srcs:
    archive = create_archive(ctx, archive_srcs, ctx.label.name)

  transitive_srcs, transitive_dart_srcs, transitive_data, transitive_deps, transitive_archives, platforms_intersection = (
      _collect_files(srcs, dart_srcs, data, deps, archive, platforms))

  if len(platforms_intersection) == 0:
    dep_platforms = ""
    for dep in deps:
      dep_platforms += ("%s : %s\n" % (dep.dart.label, dep.dart.platforms))
    fail(("\nIncompatible platforms for %s: %s" % (label, platforms)) +
         ("\n\nImmediate deps and inferred platforms\n" + dep_platforms))
  strong_analysis = None
  if enable_analysis:
    strong_analysis = ctx.new_file("%s%s.%s" % (
        compute_ddc_output_dir(label, dart_srcs),
        label.name,
        analysis_extension))
  strong_summary = None
  if enable_summaries:
    strong_summary = ctx.new_file("%s%s.%s" % (
        compute_ddc_output_dir(label, dart_srcs),
        label.name,
        api_summary_extension))
  return struct(
      label=label,
      package=package,
      lib_root=lib_root,
      strong_summary=strong_summary,
      strong_analysis=strong_analysis,
      checks=checks,
      srcs=srcs,
      outline_srcs=outline_srcs,
      dart_srcs=dart_srcs,
      data=data,
      deps=deps,
      license_files=license_files,
      transitive_srcs = transitive_srcs,
      transitive_dart_srcs = transitive_dart_srcs,
      transitive_data = transitive_data,
      transitive_deps = transitive_deps,
      archive=archive,
      transitive_archives=transitive_archives,
      platforms=platforms_intersection
  )

def _collect_files(srcs, dart_srcs, data, deps, archive, platforms):
  transitive_srcs = depset()
  transitive_dart_srcs = depset()
  transitive_data = depset()
  transitive_deps = {}
  transitive_archives = depset()
  platforms_intersection = list(platforms)
  for dep in deps:
    transitive_srcs += dep.dart.transitive_srcs
    transitive_dart_srcs += dep.dart.transitive_dart_srcs
    transitive_data += dep.dart.transitive_data
    transitive_deps += dep.dart.transitive_deps
    transitive_deps["%s" % dep.dart.label] = dep
    transitive_archives += dep.dart.transitive_archives
    for platform in platforms:
      if platform not in dep.dart.platforms:
        platforms_intersection.remove(platform)
  transitive_srcs += srcs
  transitive_dart_srcs += dart_srcs
  transitive_data += data
  if archive:
    transitive_archives += [archive]
  return (transitive_srcs, transitive_dart_srcs, transitive_data, transitive_deps, transitive_archives, platforms_intersection)

def _merge_dart_context(dart_ctx1, dart_ctx2):
  """Merges dart contexts, or fails if they are incompatible."""
  if dart_ctx1.package != dart_ctx2.package:
    fail("Incompatible packages: %s and %s" % (dart_ctx1.package,
                                               dart_ctx2.package))
  if dart_ctx1.lib_root != dart_ctx2.lib_root:
    fail("Incompatible lib_roots for package %s:\n" % dart_ctx1.package +
         "  %s declares: %s\n" % (dart_ctx1.label, dart_ctx1.lib_root) +
         "  %s declares: %s\n" % (dart_ctx2.label, dart_ctx2.lib_root) +
         "Targets in the same package must declare the same lib_root")

  return _new_dart_context(
      label = dart_ctx1.label,
      package = dart_ctx1.package,
      lib_root = dart_ctx1.lib_root,
      # TODO(davidmorgan): are these three fields ever used when merged? May be
      # better to just drop them.
      strong_summary = dart_ctx1.strong_summary,
      strong_analysis = dart_ctx1.strong_analysis,
      checks = dart_ctx1.checks,
      srcs = dart_ctx1.srcs + dart_ctx2.srcs,
      dart_srcs = dart_ctx1.dart_srcs + dart_ctx2.dart_srcs,
      data = dart_ctx1.data + dart_ctx2.data,
      deps = dart_ctx1.deps + dart_ctx2.deps,
      license_files = list(depset(dart_ctx1.license_files + dart_ctx2.license_files)),
      transitive_srcs = dart_ctx1.transitive_srcs + dart_ctx2.transitive_srcs,
      transitive_dart_srcs = dart_ctx1.transitive_dart_srcs + dart_ctx2.transitive_dart_srcs,
      transitive_data = dart_ctx1.transitive_data + dart_ctx2.transitive_data,
      transitive_deps = dart_ctx1.transitive_deps + dart_ctx2.transitive_deps,
  )

def _new_dart_context(
    label,
    package,
    lib_root,
    strong_summary = None,
    strong_analysis = None,
    checks = None,
    srcs = None,
    dart_srcs = None,
    data = None,
    deps = None,
    license_files = [],
    transitive_srcs = None,
    transitive_dart_srcs = None,
    transitive_data = None,
    transitive_deps = None):
  return struct(
      label = label,
      package = package,
      lib_root = lib_root,
      strong_summary = strong_summary,
      strong_analysis = strong_analysis,
      checks = checks,
      srcs = depset(srcs or []),
      dart_srcs = depset(dart_srcs or []),
      data = depset(data or []),
      deps = deps or [],
      license_files = license_files,
      transitive_srcs = depset(transitive_srcs or []),
      transitive_dart_srcs = depset(transitive_dart_srcs or []),
      transitive_data = depset(transitive_data or []),
      transitive_deps = dict(transitive_deps or {}),
  )

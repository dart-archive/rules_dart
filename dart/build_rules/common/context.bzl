"""Common utilities for creating and manipulating dart context providers."""

load(
    "//dart/build_rules/common:constants.bzl",
    "api_summary_extension",
    "dart_filetypes",
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
    srcs = None,
    data = None,
    deps = None,
    license_files = []):
  """Creates a dart context for a target."""
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

  srcs = set(srcs or [])
  dart_srcs = filter_files(dart_filetypes, srcs)
  data = set(data or [])
  deps = deps or []
  transitive_srcs, transitive_dart_srcs, transitive_data, transitive_deps = (
      _collect_files(srcs, dart_srcs, data, deps))
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
      srcs=srcs,
      dart_srcs=dart_srcs,
      data=data,
      deps=deps,
      license_files=license_files,
      transitive_srcs = transitive_srcs,
      transitive_dart_srcs = transitive_dart_srcs,
      transitive_data = transitive_data,
      transitive_deps = transitive_deps,
  )

def _collect_files(srcs, dart_srcs, data, deps):
  transitive_srcs = set()
  transitive_dart_srcs = set()
  transitive_data = set()
  transitive_deps = {}
  for dep in deps:
    transitive_srcs += dep.dart.transitive_srcs
    transitive_dart_srcs += dep.dart.transitive_dart_srcs
    transitive_data += dep.dart.transitive_data
    transitive_deps += dep.dart.transitive_deps
    transitive_deps["%s" % dep.dart.label] = dep
  transitive_srcs += srcs
  transitive_dart_srcs += dart_srcs
  transitive_data += data
  return (transitive_srcs, transitive_dart_srcs, transitive_data, transitive_deps)

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
      strong_summary = dart_ctx1.strong_summary,
      srcs = dart_ctx1.srcs + dart_ctx2.srcs,
      dart_srcs = dart_ctx1.dart_srcs + dart_ctx2.dart_srcs,
      data = dart_ctx1.data + dart_ctx2.data,
      deps = dart_ctx1.deps + dart_ctx2.deps,
      license_files = list(set(dart_ctx1.license_files + dart_ctx2.license_files)),
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
      srcs = set(srcs or []),
      dart_srcs = set(dart_srcs or []),
      data = set(data or []),
      deps = deps or [],
      license_files = license_files,
      transitive_srcs = set(transitive_srcs or []),
      transitive_dart_srcs = set(transitive_dart_srcs or []),
      transitive_data = set(transitive_data or []),
      transitive_deps = dict(transitive_deps or {}),
  )

"""Common utilities for creating and manipulating dart context providers."""

load(
    "//dart/build_rules/common:constants.bzl",
    "ALL_PLATFORMS",
    "analysis_extension",
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
load(
    "//dart/build_rules/common:_archive.bzl",
    "create_archive",
)

def collect_dart_context(dart_ctx):
    """Collect transitive deps in a map, merging contexts as needed."""
    ctx_map = {dart_ctx.package: dart_ctx}
    for dep in dart_ctx.transitive_deps.targets.values():
        dc = dep.dart
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
        strict_deps = None,
        srcs = None,
        generated_srcs = None,
        outline_srcs = None,
        data = None,
        deps = None,
        platforms = None,
        force_platforms = False,
        license_files = []):
    """Creates a dart context for a target.

    Args:
      ctx: The target context.
      package: The dart package name.
      lib_root: The lib folder for the package.
      enable_summaries: Whether to generate analyzer summaries.
      enable_analysis: Whether to generate analyzer output.
      checks: A file for post-processed analyzer output.
      strict_deps: The file with the results of a strict dependencies check.
      srcs: List of Target. Source dependencies.
      generated_srcs: List of File. Source dependencies that exist as files only
        (with no associated Target), typically because they've been generated
        from another action.
      outline_srcs: Source files with possibly incomplete implementations but
        full api outlines. These are intended for use when generating summaries
        only. Defaults to `srcs` if not provided.
      data: Data library dependencies.
      deps: Dart library dependencies.
      platforms: List of platforms this dart context supports. Defaults to the
        intersection of all dependency platforms or ["web", "flutter", "vm"] if
        no dependencies are provided.
      force_platforms: Forces the supported platforms to be equal to the
        supplied platforms. This is risky and should rarely be used.
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

    srcs = srcs or []
    srcs_files = depset(generated_srcs or [])
    srcs_files += [f for t in srcs for f in t.files]
    outline_srcs = depset(outline_srcs or srcs_files)
    dart_srcs = filter_files(dart_filetypes, srcs_files)
    data = data or []
    data_files = depset([f for t in data for f in t.files])
    deps = deps or []
    archive_srcs = srcs_files.to_list()

    archive = None
    if archive_srcs:
        archive = create_archive(ctx, archive_srcs, ctx.label.name)

    explicit_platforms = False
    if not platforms:
        platforms = list(ALL_PLATFORMS)
    else:
        explicit_platforms = True
        for platform in platforms:
            if platform not in ALL_PLATFORMS:
                fail(("Invalid platforms selection for %s. " % label) +
                     ("%s is not an available platform. " % platform) +
                     ("Should be one of %s" % ALL_PLATFORMS))

    transitive_srcs_targets, transitive_srcs_files, transitive_dart_srcs_files, transitive_data_targets, transitive_data_files, transitive_deps_targets, transitive_archives_files, platforms_intersection = (
        _collect_files(
            srcs,
            srcs_files,
            dart_srcs,
            data,
            data_files,
            deps,
            archive,
            platforms,
        )
    )

    if force_platforms:
        platforms_intersection = platforms

    if (len(platforms_intersection) == 0 or
        (explicit_platforms and platforms != platforms_intersection)):
        dep_platforms = ""
        for dep in deps:
            dep_platforms += (
                "%s : %s\n" % (dep.dart.label, dep.dart.platforms)
            )
        fail(("\nIncompatible platforms for %s: %s" % (label, platforms)) +
             ("\n\nImmediate deps and inferred platforms\n" + dep_platforms))
    strong_analysis = None
    if enable_analysis:
        strong_analysis = ctx.actions.declare_file("%s%s.%s" % (
            compute_ddc_output_dir(label, dart_srcs),
            label.name,
            analysis_extension,
        ))
    strong_summary = None
    if enable_summaries:
        strong_summary = ctx.actions.declare_file("%s%s.%s" % (
            compute_ddc_output_dir(label, dart_srcs),
            label.name,
            api_summary_extension,
        ))
    return struct(
        label = label,
        package = package,
        lib_root = lib_root,
        strong_summary = strong_summary,
        strong_analysis = strong_analysis,
        checks = checks,
        strict_deps = strict_deps,
        srcs = srcs_files,
        outline_srcs = outline_srcs,
        dart_srcs = dart_srcs,
        data = data_files,
        deps = deps,
        license_files = license_files,
        archive = archive,
        platforms = platforms_intersection,
        explicit_platforms = explicit_platforms,
        force_platforms = force_platforms,
        transitive_srcs = struct(
            targets = transitive_srcs_targets,
            files = transitive_srcs_files,
        ),
        transitive_dart_srcs = struct(
            files = transitive_dart_srcs_files,
        ),
        transitive_data = struct(
            targets = transitive_data_targets,
            files = transitive_data_files,
        ),
        transitive_deps = struct(
            targets = transitive_deps_targets,
        ),
        transitive_archives = struct(
            files = transitive_archives_files,
        ),
    )

def _collect_files(
        srcs_attrs,
        srcs_files,
        dart_srcs_files,
        data_attrs,
        data_files,
        deps_attrs,
        archive_file,
        platforms):
    transitive_srcs_targets = {}
    transitive_srcs_files = depset()
    transitive_dart_srcs_files = depset()
    transitive_data_targets = {}
    transitive_data_files = depset()
    transitive_deps_targets = {}
    transitive_archives_files = depset()
    platforms_intersection = list(platforms)
    for dep in deps_attrs:
        transitive_srcs_targets.update(dep.dart.transitive_srcs.targets)
        transitive_srcs_files += dep.dart.transitive_srcs.files
        transitive_dart_srcs_files += dep.dart.transitive_dart_srcs.files
        transitive_data_targets.update(dep.dart.transitive_data.targets)
        transitive_data_files += dep.dart.transitive_data.files
        transitive_deps_targets.update(dep.dart.transitive_deps.targets)
        transitive_deps_targets["%s" % dep.dart.label] = dep
        transitive_archives_files += dep.dart.transitive_archives.files
        for platform in platforms:
            if platform not in dep.dart.platforms and platform in platforms_intersection:
                platforms_intersection.remove(platform)
    transitive_srcs_targets.update({"%s" % s.label: s for s in srcs_attrs})
    transitive_srcs_files += srcs_files
    transitive_dart_srcs_files += dart_srcs_files
    transitive_data_targets.update({"%s" % d.label: d for d in data_attrs})
    transitive_data_files += data_files
    if archive_file:
        transitive_archives_files += [archive_file]
    return (
        transitive_srcs_targets,
        transitive_srcs_files,
        transitive_dart_srcs_files,
        transitive_data_targets,
        transitive_data_files,
        transitive_deps_targets,
        transitive_archives_files,
        platforms_intersection,
    )

def _merge_dart_context(dart_ctx1, dart_ctx2):
    """Merges dart contexts, or fails if they are incompatible."""
    if dart_ctx1.package != dart_ctx2.package:
        fail("Incompatible packages: %s and %s" % (
            dart_ctx1.package,
            dart_ctx2.package,
        ))
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
        strict_deps = dart_ctx1.strict_deps,
        srcs = dart_ctx1.srcs + dart_ctx2.srcs,
        dart_srcs = dart_ctx1.dart_srcs + dart_ctx2.dart_srcs,
        data = dart_ctx1.data + dart_ctx2.data,
        deps = dart_ctx1.deps + dart_ctx2.deps,
        license_files = depset(dart_ctx1.license_files + dart_ctx2.license_files).to_list(),
        transitive_srcs_targets = dict(dart_ctx1.transitive_srcs.targets.items() + dart_ctx2.transitive_srcs.targets.items()),
        transitive_srcs_files = dart_ctx1.transitive_srcs.files + dart_ctx2.transitive_srcs.files,
        transitive_dart_srcs_files = dart_ctx1.transitive_dart_srcs.files + dart_ctx2.transitive_dart_srcs.files,
        transitive_data_targets = dict(dart_ctx1.transitive_data.targets.items() + dart_ctx2.transitive_data.targets.items()),
        transitive_data_files = dart_ctx1.transitive_data.files + dart_ctx2.transitive_data.files,
        transitive_deps_targets = dict(dart_ctx1.transitive_deps.targets.items() + dart_ctx2.transitive_deps.targets.items()),
    )

def _new_dart_context(
        label,
        package,
        lib_root,
        strong_summary = None,
        strong_analysis = None,
        checks = None,
        strict_deps = None,
        srcs = None,
        dart_srcs = None,
        data = None,
        deps = None,
        license_files = [],
        transitive_srcs_targets = None,
        transitive_srcs_files = None,
        transitive_dart_srcs_files = None,
        transitive_data_targets = None,
        transitive_data_files = None,
        transitive_deps_targets = None):
    return struct(
        label = label,
        package = package,
        lib_root = lib_root,
        strong_summary = strong_summary,
        strong_analysis = strong_analysis,
        checks = checks,
        strict_deps = strict_deps,
        srcs = depset(srcs or []),
        dart_srcs = depset(dart_srcs or []),
        data = depset(data or []),
        deps = deps or [],
        license_files = license_files,
        transitive_srcs = struct(
            targets = dict(transitive_srcs_targets or {}),
            files = depset(transitive_srcs_files or []),
        ),
        transitive_dart_srcs = struct(
            files = depset(transitive_dart_srcs_files or []),
        ),
        transitive_data = struct(
            targets = dict(transitive_data_targets or {}),
            files = depset(transitive_data_files or []),
        ),
        transitive_deps = struct(
            targets = dict(transitive_deps_targets or {}),
        ),
    )

load(
    ":common.bzl",
    "compute_ddc_output_dir",
    "has_dart_sources",
    "make_dart_context",
)
# TODO: Migrate both of these to an aspect? This would eliminate the
# ddc/analyzer dependency for targets which don't actually need them.
load(":analyze.bzl", "summary_action")
load(":ddc.bzl", "ddc_action")

def dart_library_impl(ctx):
  """Implements the dart_library() rule."""

  dart_ctx = make_dart_context(
      ctx,
      srcs = ctx.attr.srcs,
      data = ctx.attr.data,
      deps = ctx.attr.deps,
      enable_summaries = ctx.attr.enable_summaries,
      package = ctx.attr.pub_pkg_name,
  )

  summary_action(ctx, dart_ctx)
  files_provider = depset([dart_ctx.strong_summary])

  ddc_output = None
  source_map_output = None
  if ctx.attr.enable_ddc:
    # Find the top level dir under which all srcs live, can only have one per
    # dart_library, and that is where we output the js file.
    output_dir = compute_ddc_output_dir(ctx.label, dart_ctx.dart_srcs)

    ddc_output = ctx.new_file("%s%s.js" % (output_dir, ctx.label.name))
    source_map_output = ctx.new_file("%s%s.js.map" % (output_dir, ctx.label.name))
    files_provider += [ddc_output, source_map_output]

    if not has_dart_sources(ctx.files.srcs):
      ctx.file_action(
          output=ddc_output,
          content=("// intentionally empty: package %s has no dart sources" %
                   ctx.label.name))
      ctx.file_action(
          output=source_map_output,
          content=("// intentionally empty: package %s has no dart sources" %
                   ctx.label.name))
    else:
      ddc_action(ctx, dart_ctx, ddc_output, source_map_output)

  return struct(
      dart=dart_ctx,
      ddc=struct(
        enabled=ctx.attr.enable_ddc,
        output=ddc_output,
        sourcemap=source_map_output,
      ),
      files=files_provider,
  )

load(":common.bzl", "collect_files", "layout_action", "package_spec_action")

def dart2js_action(ctx, dart_ctx, script_file,
                   checked, csp, dump_info, minify, preserve_uris,
                   js_output, part_outputs, other_outputs):
  """dart2js compile action."""
  # Create a build directory.
  build_dir = ctx.label.name + ".build/"

  # Emit package spec.
  package_spec_path = ctx.label.package + "/" + ctx.label.name + ".packages"
  package_spec = ctx.new_file(build_dir + package_spec_path)
  package_spec_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      output=package_spec,
  )

  # Build a flattened directory of dart2js inputs, including inputs from the
  # src tree, genfiles, and bin.
  all_srcs, _ = collect_files(dart_ctx)
  build_dir_files = layout_action(
      ctx=ctx,
      srcs=all_srcs,
      output_dir=build_dir,
  )
  out_script = build_dir_files[script_file.short_path]

  # Compute action inputs.
  inputs = ctx.files._dart2js
  inputs += ctx.files._dart2js_support
  inputs += build_dir_files.values()
  inputs += [package_spec]

  # Compute dart2js args.
  dart2js_args = [
      "--packages=%s" % package_spec.path,
      "--out=%s" % js_output.path,
  ]
  if checked:
    dart2js_args += ["--checked"]
  if csp:
    dart2js_args += ["--csp"]
  if dump_info:
    dart2js_args += ["--dump-info"]
  if minify:
    dart2js_args += ["--minify"]
  if preserve_uris:
    dart2js_args += ["--preserve-uris"]
  dart2js_args += [out_script.path]
  ctx.action(
      inputs=inputs,
      executable=ctx.executable._dart2js_helper,
      arguments=[
          str(ctx.label),
          str(ctx.attr.deferred_lib_count),
          ctx.outputs.js.path,
          ctx.executable._dart2js.path,
      ] + dart2js_args,
      outputs=[js_output] + part_outputs + other_outputs,
      progress_message="Compiling with dart2js %s" % ctx,
      mnemonic="Dart2jsCompile",
  )

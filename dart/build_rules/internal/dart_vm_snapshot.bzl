load(":common.bzl", "collect_files", "layout_action", "make_dart_context", "package_spec_action")

def dart_vm_snapshot_action(ctx, dart_ctx, output, vm_flags, script_file, script_args):
  """Emits a Dart VM snapshot."""
  build_dir = ctx.label.name + ".build/"

  # Emit package spec.
  package_spec_path = ctx.label.package + "/" + ctx.label.name + ".packages"

  # TODO (nshahan) this will not work if the package name does actually start
  # with vendor.
  if package_spec_path.startswith("vendor_"):
    package_spec_path = package_spec_path[len("vendor_"):]

  package_spec = ctx.new_file(build_dir + package_spec_path)
  package_spec_action(
      ctx=ctx,
      output=package_spec,
      dart_ctx=dart_ctx,
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

  # TODO(cbracken) assert --snapshot not in flags
  # TODO(cbracken) assert --packages not in flags
  arguments = [
      "--packages=%s" % package_spec.path,
      "--snapshot=%s" % output.path,
  ]
  arguments += vm_flags
  arguments += [out_script.path]
  arguments += script_args
  ctx.action(
      inputs=build_dir_files.values() + [package_spec],
      outputs=[output],
      executable=ctx.executable._dart_vm,
      arguments=arguments,
      progress_message="Building Dart VM snapshot %s" % ctx,
      mnemonic="DartVMSnapshot",
  )

def dart_vm_snapshot_impl(ctx):
  """Implements the dart_vm_snapshot build rule."""
  dart_ctx = make_dart_context(ctx.label,
                               srcs=ctx.files.srcs,
                               data=ctx.files.data,
                               deps=ctx.attr.deps,
                               pub_pkg_name=ctx.attr.pub_pkg_name)
  dart_vm_snapshot_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      output=ctx.outputs.snapshot,
      vm_flags=ctx.attr.vm_flags,
      script_file=ctx.file.script_file,
      script_args=ctx.attr.script_args,
  )
  return struct()

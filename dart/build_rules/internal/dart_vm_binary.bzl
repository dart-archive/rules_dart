load(":common.bzl", "collect_files", "make_dart_context", "package_spec_action")
load(":dart_vm_snapshot.bzl", "dart_vm_snapshot_action")

def dart_vm_binary_impl(ctx):
  """Implements the dart_vm_binary() rule."""
  dart_ctx = make_dart_context(ctx.label,
                               srcs=ctx.files.srcs,
                               data=ctx.files.data,
                               deps=ctx.attr.deps,
                               pub_pkg_name=ctx.attr.pub_pkg_name)

  if ctx.attr.snapshot:
    # Build snapshot
    out_snapshot = ctx.new_file(ctx.label.name + ".snapshot")
    dart_vm_snapshot_action(
        ctx=ctx,
        dart_ctx=dart_ctx,
        output=out_snapshot,
        vm_flags=ctx.attr.vm_flags,
        script_file=ctx.file.script_file,
        script_args=ctx.attr.script_args,
    )
    script_file = out_snapshot
  else:
    script_file = ctx.file.script_file

  # Emit package spec.
  package_spec = ctx.new_file(ctx.label.name + ".packages")
  package_spec_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      output=package_spec,
  )

  # Emit entrypoint script.
  ctx.template_action(
      output=ctx.outputs.executable,
      template=ctx.file._entrypoint_template,
      executable=True,
      substitutions={
          "%workspace%": ctx.workspace_name,
          "%dart_vm%": ctx.executable._dart_vm.short_path,
          "%package_spec%": package_spec.short_path,
          "%vm_flags%": " ".join(ctx.attr.vm_flags),
          "%script_file%": script_file.short_path,
          "%script_args%": " ".join(ctx.attr.script_args),
      },
  )

  # Compute runfiles.
  all_srcs, all_data = collect_files(dart_ctx)
  runfiles_files = all_data + all_srcs + [
      ctx.executable._dart_vm,
      ctx.outputs.executable,
      package_spec,
  ]
  if ctx.attr.snapshot:
    runfiles_files += [out_snapshot]

  runfiles = ctx.runfiles(
      files=list(runfiles_files),
      collect_data=True,
  )

  return struct(
      runfiles=runfiles,
  )

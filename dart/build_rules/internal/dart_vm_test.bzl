load(":common.bzl", "make_dart_context", "package_spec_action")

def dart_vm_test_impl(ctx):
  """Implements the dart_vm_test() rule."""
  dart_ctx = make_dart_context(
      ctx,
      srcs = ctx.attr.srcs,
      data = ctx.attr.data,
      deps = ctx.attr.deps,
      package = ctx.attr.pub_pkg_name,
  )

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
          "%script_file%": ctx.file.script_file.short_path,
          "%script_args%": " ".join(ctx.attr.script_args),
      },
  )

  # Compute runfiles.
  runfiles_files = dart_ctx.transitive_data.files + [
      ctx.executable._dart_vm,
      ctx.outputs.executable,
  ]
  runfiles_files += dart_ctx.transitive_srcs.files
  runfiles_files += [package_spec]
  runfiles = ctx.runfiles(
      files=list(runfiles_files),
  )

  return struct(
      runfiles=runfiles,
      instrumented_files=struct(
          source_attributes=["srcs"],
          dependency_attributes=["deps"],
      ),
  )

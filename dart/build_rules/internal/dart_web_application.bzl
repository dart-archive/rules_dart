load(":common.bzl", "make_dart_context", "relative_path", "strip_extension")
load(":dart2js.bzl", "dart2js_action")

def dart_web_application_impl(ctx):
  """Implements the dart_web_application build rule."""
  dart_ctx = make_dart_context(
      ctx,
      srcs = ctx.attr.srcs,
      data = ctx.attr.data,
      deps = ctx.attr.deps,
  )

  # Compute outputs.
  output_js = ctx.outputs.js
  other_outputs = [
      ctx.outputs.deps_file,
      ctx.outputs.sourcemap,
  ]
  if ctx.attr.dump_info:
    other_outputs += [ctx.outputs.info_json]

  packages_files = []
  deploy_dir = "%s.deploy" % ctx.label.name
  output_js_dir = output_js.short_path[:output_js.short_path.rfind("/")]
  if ctx.attr.create_packages_dir:
    packages_files = _packages_dir_action(
        ctx=ctx, dart_ctx=dart_ctx,
        deploy_dir=deploy_dir,
        output_dir=output_js_dir)

  # Invoke dart2js.
  dart2js_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      script_file=ctx.file.script_file,
      checked=ctx.attr.checked,
      csp=ctx.attr.csp,
      dump_info=ctx.attr.dump_info,
      emit_tar=ctx.attr.emit_tar,
      extra_inputs=packages_files,
      fast_startup=ctx.attr.fast_startup,
      library_root=None,
      minify=ctx.attr.minify,
      preserve_uris=ctx.attr.preserve_uris,
      deploy_dir=deploy_dir,
      output_js=output_js,
      other_outputs=other_outputs,
      trust_primitives=ctx.attr.trust_primitives,
      trust_type_annotations=ctx.attr.trust_type_annotations,
  )

  # TODO(cbracken) aggregate, inject licenses
  return struct(files=depset(other_outputs) + [output_js] + packages_files)

def dart_web_application_outputs(output_js, dump_info, emit_tar, script_file):
  """Returns the expected output map for dart_web_application."""
  output_js = output_js or "%s.js" % script_file.name
  outputs = {
      "js": output_js,
      "deps_file": "%s.deps" % output_js,
      "sourcemap": "%s.map" % output_js,
      "packages_file": "%{name}.packages",
  }
  if dump_info:
    outputs["info_json"] = "%s.info.json" % output_js
  if emit_tar:
    outputs["tar"] = "%s.tar" % output_js
  return outputs

def _packages_dir_action(ctx, dart_ctx, deploy_dir, output_dir):
  """Generates a packages directory for a target.

  Note that this action also outputs files from the root package which are not
  under `lib`. These will be outside the actual `packages` directory.

  Args:
    ctx: The Bazel BUILD context
    dart_ctx: A context built for Dart-specific BUILD attributes
    deploy_dir: The top level directory under which all files should be placed
    output_dir: A relative path under deploy_dir, under which the `packages`
      directory should be created.

  Returns:
    All the files that were created.
  """
  commands = []
  output_files = []
  if not deploy_dir.endswith("/"):
    deploy_dir += "/"
  if not output_dir.endswith("/"):
    output_dir += "/"

  srcs = depset()
  for dep in dart_ctx.transitive_deps.targets.values():
    package = dep.dart.package
    for src_file in dep.dart.srcs:
      if src_file in srcs:
        continue

      root_relative_path = src_file.short_path
      if root_relative_path.startswith("../"):
        root_relative_path = root_relative_path[len("../"):]

      if root_relative_path.startswith(dep.dart.lib_root):
        lib_path = root_relative_path[len(dep.dart.lib_root):]
        dest_file = ctx.new_file(
            deploy_dir + output_dir + "packages/" + package + "/" + lib_path)
      elif dart_ctx.label.package == dep.dart.label.package:
        dest_file = ctx.new_file(deploy_dir + src_file.short_path)
      else:
        continue

      dest_dir = dest_file.path[:dest_file.path.rfind("/")]
      link_target = relative_path(dest_dir, src_file.path)
      commands += ["ln -s '%s' '%s'" % (link_target, dest_file.path)]
      output_files += [dest_file]

    # Wait and add all of these at the end since its more efficient to add the
    # whole set at once.
    srcs += dep.dart.srcs

  # Emit packages dir script.
  suffix = output_dir[:-1].replace("/", "_")
  packages_action_out = ctx.new_file(
      "%s_%s_packages.sh" % (suffix, ctx.label.name))
  ctx.file_action(
      output=packages_action_out,
      content="#!/bin/bash\n" + "\n".join(commands),
      executable=True,
  )

  # Invoke the packages dir action.
  ctx.action(
      inputs=list(srcs),
      outputs=output_files,
      executable=packages_action_out,
      progress_message = "Building packages dir for %s" % ctx,
      mnemonic = "DartPackagesDir",
  )
  return output_files

load(":common.bzl", "make_dart_context")
load(":dart2js.bzl", "dart2js_action")

def dart_web_application_impl(ctx):
  """Implements the dart_web_application build rule."""
  dart_ctx = make_dart_context(ctx.label,
                               srcs=ctx.files.srcs,
                               data=ctx.files.data,
                               deps=ctx.attr.deps)

  # Compute outputs.
  js_output = ctx.outputs.js
  other_outputs = [
      ctx.outputs.deps_file,
      ctx.outputs.sourcemap,
  ]
  if ctx.attr.dump_info:
    other_outputs += [ctx.outputs.info_json]
  part_outputs = []
  for i in range(1, ctx.attr.deferred_lib_count + 1):
    part_outputs += [getattr(ctx.outputs, "part_js%s" % i)]
    other_outputs += [getattr(ctx.outputs, "part_sourcemap%s" % i)]

  # Invoke dart2js.
  dart2js_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      script_file=ctx.file.script_file,
      checked=ctx.attr.checked,
      csp=ctx.attr.csp,
      dump_info=ctx.attr.dump_info,
      minify=ctx.attr.minify,
      preserve_uris=ctx.attr.preserve_uris,
      js_output=js_output,
      part_outputs=part_outputs,
      other_outputs=other_outputs,
  )

  # TODO(cbracken) aggregate, inject licenses
  return struct()

def dart_web_application_outputs(dump_info, deferred_lib_count):
  """Returns the expected output map for dart_web_application."""
  outputs = {
      "js": "%{name}.js",
      "deps_file": "%{name}.js.deps",
      "sourcemap": "%{name}.js.map",
  }
  if dump_info:
    outputs["info_json"] = "%{name}.js.info.json"
  for i in range(1, deferred_lib_count + 1):
    outputs["part_js%s" % i] = "%%{name}.js_%s.part.js" % i
    outputs["part_sourcemap%s" % i] = "%%{name}.js_%s.part.js.map" % i
  return outputs

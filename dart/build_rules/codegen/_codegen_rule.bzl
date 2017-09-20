"""Builds custom skylark rules scoped to a specific dart_codegen_binary."""

load(":_codegen_action.bzl", "codegen_action")
load("//dart/build_rules/internal:common.bzl", "SDK_SUMMARIES")

def dart_codegen_rule(
    codegen_binary,
    in_extension,
    out_extensions,
    generator_args = [],
    arg_prefix = "",
    aspect = None,
    input_provider = "",
    supports_outline_codegen = False,
    outline_summary_deps = [],):
  """Builds custom skylark rules scoped to a specific dart_codegen_binary.

  See codegen.bzl for usage of the generated rule.

  Args:
    codegen_binary: A binary created with a dart_codegen_binary rule.
    in_extension: The file extension for files which are primary inputs.
    out_extensions: The file extensions which are generated for each primary
      input.
    generator_args: Optional. Arguments that are always passed to the codegen
      binary. These will be merged with the generator_args passed by callers of
      the created rule. If any arguments impact the file extensions created by
      the binary they must be included here.
    aspect: Optional. An Aspect created with `dart_codegen_aspect` to collect
      extra source that need to be read within dependencies.
    input_provider: Optional. If an aspect is provided, this must match the name
      used when creating it.
    supports_outline_codegen: Whether or not this code generator supports
      generating outlines based on a predefined set of summaries and not
      transitive ones. When the outline only should be output, an additional
      `--outline-only` flag will be passed to the codegen_binary along with any
      other arguments.
    outline_summary_deps: If supports_outline_codegen == True, the summaries to
      pass to the outline codegen action. All transitive summaries of these deps
      will also be available.

  Returns:
    A skylark rule which runs the provided Builders.
  """

  if aspect:
    aspects = [aspect]
  else:
    aspects = []

  return rule(
      implementation = _codegen_impl,
      attrs = {
          "deps": attr.label_list(allow_files = True, aspects = aspects),
          "forced_deps": attr.label_list(allow_files = True),
          "srcs": attr.label_list(allow_files = True),
          "generate_for": attr.label_list(allow_files = True),
          "generator_args": attr.string_list(),
          "outline_summary_deps": attr.label_list(
              default = outline_summary_deps,
              providers = ["dart"],
          ),
          "_in_extension": attr.string(
              default = in_extension,
          ),
          "_out_extensions": attr.string_list(
              default = out_extensions,
          ),
          "_input_provider": attr.string(default = input_provider),
          "_generator": attr.label(
              cfg="host",
              executable=True,
              default = Label(codegen_binary),
              providers = ["dart_codegen_config"],
          ),
          "_default_generator_args": attr.string_list(default=generator_args),
          "_arg_prefix": attr.string(default = arg_prefix),
          "_sdk": attr.label(
              default = Label(SDK_SUMMARIES),
              allow_files = True,
          ),
          "_supports_outline_codegen": attr.bool(
              default = supports_outline_codegen,
          ),
      },
      outputs = _compute_outs,
  )

def _compute_outs(_in_extension, _out_extensions, srcs, generate_for):
  if not srcs and not generate_for:
    fail("either `srcs` or `generate_for` must not be empty")
  if not _out_extensions:
    fail("must not be empty", attr="_out_extensions")

  if not generate_for:
    generate_for = srcs

  outs = {}
  for label in generate_for:
    if label.name.endswith(_in_extension):
      for ext in _out_extensions:
        out_name = "%s%s" % (label.name[:-1 * len(_in_extension)], ext)
        outs[out_name] = out_name
  return outs

def _codegen_impl(ctx):
  if not ctx.files.srcs and not ctx.files.generate_for:
    fail("Must provide either `srcs` or `generate_for`")

  config = ctx.attr._generator.dart_codegen_config
  generator_args = ctx.attr._default_generator_args + ctx.attr.generator_args

  log_level = "warning"
  if "DART_CODEGEN_LOG_LEVEL" in ctx.var:
    log_level = ctx.var["DART_CODEGEN_LOG_LEVEL"]

  forced_dep_files = depset()
  for dep in ctx.attr.forced_deps:
    if hasattr(dep, "dart"):
      forced_dep_files += dep.dart.srcs
      forced_dep_files += dep.dart.data
    else:
      forced_dep_files += dep.files

  full_srcs = codegen_action(
      ctx,
      ctx.files.srcs,
      ctx.attr._in_extension,
      ctx.attr._out_extensions,
      ctx.executable._generator,
      forced_deps = forced_dep_files,
      generator_args = generator_args,
      arg_prefix = ctx.attr._arg_prefix,
      input_provider = ctx.attr._input_provider,
      log_level = log_level,
      generate_for = ctx.files.generate_for,
      use_summaries = config.use_summaries,
  )

  if ctx.attr._supports_outline_codegen:
    outline_summary_deps = ctx.attr.outline_summary_deps
    outline_srcs = codegen_action(
        ctx,
        ctx.files.srcs,
        ctx.attr._in_extension,
        ctx.attr._out_extensions,
        ctx.executable._generator,
        forced_deps = forced_dep_files,
        generator_args = generator_args,
        arg_prefix = ctx.attr._arg_prefix,
        input_provider = ctx.attr._input_provider,
        log_level = log_level,
        generate_for = ctx.files.generate_for,
        use_summaries = config.use_summaries,
        outline_only = True,
        outline_summary_deps = outline_summary_deps,
    )
  else:
    outline_srcs = full_srcs

  return struct(
      dart_codegen = struct(
          outline_srcs = outline_srcs,
          full_srcs = full_srcs,
      ),
      files = full_srcs,
  )

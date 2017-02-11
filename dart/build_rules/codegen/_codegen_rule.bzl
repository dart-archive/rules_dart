"""Builds custom skylark rules scoped to a specific dart_codegen_binary."""

load(":_codegen_action.bzl", "codegen_action")
load("//dart/build_rules/internal:common.bzl", "SDK_SUMMARIES")

def dart_codegen_rule(
    codegen_binary,
    in_extension,
    out_extensions,
    generator_args = [],
    aspect = None,
    input_provider = ""):
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
    input_provider: Optiona. If an aspect is provided, this must match the name
      used when creating it.

  Returns:
    A skylark rule which runs the provided Builders.
  """

  joined_out = ",".join(out_extensions)

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
          "log_level": attr.string(default = "warning"),
          "in_extension": attr.string(
              default = in_extension,
              values = [in_extension],
          ),
          "out_extensions": attr.string(
              default = joined_out,
              values = [joined_out],
          ),
          "_input_provider": attr.string(default = input_provider),
          "_generator": attr.label(
              cfg="host",
              executable=True,
              default = Label(codegen_binary),
              providers = ["dart_codegen_config"],
          ),
          "_forced_generator_args": attr.string_list(default=generator_args),
          "_sdk": attr.label(
              default = Label(SDK_SUMMARIES),
              allow_files = True,
          ),
      },
      outputs = _compute_outs,
  )

def _compute_outs(in_extension, out_extensions, srcs, generate_for):
  if not srcs and not generate_for:
    fail("either `srcs` or `generate_for` must not be empty")
  if not out_extensions:
    fail("must not be empty", attr="out_extensions")

  if not generate_for:
    generate_for = srcs

  split_out = out_extensions.split(",")
  outs = {}
  for label in generate_for:
    if label.name.endswith(in_extension):
      for ext in split_out:
        out_name = "%s%s" % (label.name[:-1 * len(in_extension)], ext)
        outs[out_name] = out_name
  return outs

def _codegen_impl(ctx):
  if not ctx.files.srcs and not ctx.files.generate_for:
    fail("Must provide either `srcs` or `generate_for`")

  config = ctx.attr._generator.dart_codegen_config
  generator_args = ctx.attr.generator_args + ctx.attr._forced_generator_args

  outs = codegen_action(
      ctx,
      ctx.files.srcs,
      ctx.attr.in_extension,
      ctx.attr.out_extensions.split(","),
      ctx.executable._generator,
      forced_deps = ctx.files.forced_deps,
      generator_args = generator_args,
      input_provider = ctx.attr._input_provider,
      log_level = ctx.attr.log_level,
      generate_for = ctx.files.generate_for,
      use_summaries = config.use_summaries,
      use_resolver = config.use_resolver,
  )

  return struct(files=outs)

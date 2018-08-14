"""Build a dart_vm_binary to run code generation."""

load("//third_party/bazel_skylib:lib.bzl", "dicts")
load("//dart/build_rules/internal:common.bzl", "SDK_LIB_FILES")
load("//dart/build_rules:vm.bzl", "dart_vm")
load(":_labels.bzl", "labels")
load(
    "//third_party/dart/rules_dart/build_rules/common:kernel.bzl",
    _kernel_vm_aspect = "kernel_vm_aspect",
)
load(
    "//dart/build_rules/internal:common.bzl",
    _dartvm_target = "dartvm_target",
    _kernel_worker_snapshot = "kernel_worker_snapshot",
    _sdk_summary_dill = "sdk_summary_dill",
)

def _script_action(ctx):
    """Builds an executable Dart script to run code generation."""
    default_content = [
        "r'%s' : r'''%s'''" % (extension, content)
        for extension, content in ctx.attr.default_content.items()
    ]
    ctx.template_action(
        output = ctx.outputs.script_file,
        template = ctx.file._template_file,
        substitutions = {
            "$builderImport": ctx.attr.builder_import,
            "$builderFactories": ", ".join(ctx.attr.builder_factories),
            "$defaultContent": ", ".join(default_content),
        },
    )

def _codegen_binary_impl(ctx):
    _script_action(ctx)

    use_summaries = ctx.attr.use_summaries
    if not ctx.attr.use_resolver:
        use_summaries = False

    data = []
    if ctx.attr.use_resolver and not use_summaries:
        data = [ctx.attr._sdk_lib_files]

    runfiles = dart_vm.binary_action(
        ctx,
        ctx.outputs.script_file,
        ctx.attr.srcs,
        ctx.attr.deps + [ctx.attr._codegen_dep],
        generated_srcs = [ctx.outputs.script_file],
        data = data,
        run_with_kernel = not ctx.attr.run_from_source,
    )

    return struct(
        runfiles = runfiles,
        dart_codegen_config = struct(
            use_summaries = use_summaries,
            use_resolver = ctx.attr.use_resolver,
        ),
    )

_codegen_binary_attrs = dicts.add(dart_vm.common_attrs, {
    "srcs": attr.label_list(
        allow_files = True,
        mandatory = True,
    ),
    "deps": attr.label_list(providers = ["dart"], aspects = [_kernel_vm_aspect]),
    "builder_import": attr.string(mandatory = True),
    "builder_factories": attr.string_list(mandatory = True),
    "default_content": attr.string_dict(),
    "use_summaries": attr.bool(default = True),
    "use_resolver": attr.bool(default = True),
    "run_from_source": attr.bool(default = False),
    "_codegen_dep": attr.label(default = labels.package, aspects = [_kernel_vm_aspect]),
    "_template_file": attr.label(
        default = labels.template,
        allow_files = True,
        single_file = True,
    ),
    "_sdk_lib_files": attr.label(
        default = Label(SDK_LIB_FILES),
        allow_files = True,
    ),
    "_sdk_summary": attr.label(
        default = Label(_sdk_summary_dill()),
        allow_files = True,
        single_file = True,
    ),
    "_kernel_worker_snapshot": attr.label(
        default = Label(_kernel_worker_snapshot()),
        single_file = True,
    ),
    "_dart_vm": attr.label(
        allow_files = True,
        single_file = True,
        executable = True,
        cfg = "host",
        default = Label(_dartvm_target()),
    ),
})

_codegen_binary = rule(
    attrs = _codegen_binary_attrs,
    executable = True,
    outputs = {"script_file": "bin/%{name}_generate.dart"},
    implementation = _codegen_binary_impl,
)

def dart_codegen_binary(
        name,
        srcs,
        deps,
        builder_import,
        builder_factories,
        default_content = {},
        use_summaries = True,
        use_resolver = True,
        run_from_source = False,
        **kwargs):
    """Build a dart_vm_binary to run code generation.

    The resulting binary can be passed as the `generator` argument to
    dart_codegen_rule to create a custom skylark rule that runs code generation
    and can used by clients.

    This rule will create a script that can run one or more Builder instances from
    the specificied builder factories. A builder factory is a top level method
    from `BuilderOptions` to `Builder` as defined in package:build.

    For example, if there is a file 'lib/builder.dart' which has the top level
    method `Builder myBuilder(BuilderOptions options) => new MyBuilder(options);`

    dart_codegen_binary(
       name = "my_codegen",
       srcs = ["lib/builder.dart"],
       builder_import = "my_package_name/builder.dart",
       builder_factories = ["myBuilder"],
       deps = [],
    )

    Args:
      name: The Bazel label for the created target
      srcs: Dart files comprising the dart_library containing builder factories.
      deps: Bazel dependencies of the library containg builder factories.
      builder_import: A Dart import string <package>/<library>.dart which exports
        the builder factories.
      builder_factories: The names of the top level builder factories. These must
        be public.
      use_summaries: Whether the Builders are compatible with summarie resolvers.
        Defaults to True.
      use_resolver: Whether the Builders need analyser resolution of Dart code.
        Defaults to True.
      default_content: Optional. A map from generated file extension to string
        contents for that file. If the builders fail to output a file this value
        will be output instead.
    """
    _codegen_binary(
        name = name,
        srcs = srcs,
        deps = deps,
        builder_import = builder_import,
        builder_factories = builder_factories,
        default_content = default_content,
        use_summaries = use_summaries,
        use_resolver = use_resolver,
        run_from_source = run_from_source,
        **kwargs
    )

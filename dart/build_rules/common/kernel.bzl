"""Dart rules for creating Kernel (.dill) files."""

load(
    "//dart/build_rules/common:package_spec.bzl",
    _package_spec_action = "package_spec_action",
)
load(
    "//dart/build_rules/internal:common.bzl",
    _dartvm_target = "dartvm_target",
    _kernel_worker_snapshot = "kernel_worker_snapshot",
    _sdk_summary_dill = "sdk_summary_dill",
)

def _make_package_uri(dart_ctx, short_path, prefix = ""):
    if short_path.startswith(dart_ctx.lib_root):
        return "package:%s/%s" % (
            dart_ctx.package,
            short_path[len(dart_ctx.lib_root):],
        )
    else:
        return "google3:///%s%s" % (prefix, short_path)

def _make_kernel_file(
        ctx,
        dart_ctx,
        transitive_kernel_files,
        kernel_output,
        srcs):
    """Creates a kernel file for the provided sources."""

    dart_vm = ctx.file._dart_vm
    sdk_summary = ctx.file._sdk_summary
    kernel_worker_snapshot = ctx.file._kernel_worker_snapshot

    package_spec = ctx.actions.declare_file(ctx.label.name + ".kernel.packages")
    _package_spec_action(
        ctx = ctx,
        dart_ctx = dart_ctx,
        output = package_spec,
        use_relative_path = True,
    )

    # TODO(grouma) - Run this as a worker.
    ctx.actions.run_shell(
        outputs = [kernel_output],
        inputs = transitive_kernel_files + srcs +
                 [
                     kernel_worker_snapshot,
                     package_spec,
                     sdk_summary,
                     dart_vm,
                 ],
        arguments = [
                        dart_vm.path,
                        kernel_worker_snapshot.path,
                        "--output " + kernel_output.path,
                        "--packages-file google3:///" + package_spec.short_path,
                        "--dart-sdk-summary " + sdk_summary.path,
                        "--multi-root " + ctx.configuration.bin_dir.path,
                        "--multi-root " + ctx.configuration.genfiles_dir.path,
                        "--multi-root .",
                        "--multi-root-scheme google3",
                        "--no-summary-only",
                        "--exclude-non-sources",
                        # Use ctx.action.args to pass the depsets instead.
                        # This will improve performance and memory usage.
                    ] + [
                        "--source=" + _make_package_uri(dart_ctx, file.short_path)
                        for file in srcs
                    ] +
                    [
                        "--input-linked=google3:///" + file.short_path
                        for file in transitive_kernel_files
                    ],
        command = ("$@;"),
        mnemonic = "DartKernel",
        progress_message = "Building kernel file %s" % (ctx.label),
    )

def concat_kernel_files(ctx, dart_ctx, kernel_type, output = None):
    """Concatenates all transitive kernel files for a target."""

    transitive_kernel_files = _transitive_kernel_files(dart_ctx.deps, kernel_type)
    if dart_ctx.srcs:
        kernel_vm_output = ctx.actions.declare_file("%s.vm.dill" % ctx.label.name)
        _make_kernel_file(
            ctx,
            dart_ctx,
            transitive_kernel_files,
            kernel_vm_output,
            dart_ctx.srcs,
        )

        # Add the kernel output to the transitive kernel files
        transitive_kernel_files = depset(
            [kernel_vm_output],
            transitive = [transitive_kernel_files],
            order = "topological",
        )
    ctx.actions.run_shell(
        outputs = [output],
        inputs = transitive_kernel_files,
        # TODO(grouma) - Use ctx.args here. This pattern
        # has performance implications.
        arguments = [output.path] + [
            file.path
            for file in transitive_kernel_files.to_list()
        ],
        command = "cat ${@:2} > $1",
        mnemonic = "DartKernelConcat",
        progress_message = "Concatenating kernel files %s" % (ctx.label),
    )

def _transitive_kernel_files(deps, kernel_type):
    """Collects transitive kernel files, of a provided type, for a set of deps."""

    return depset(
        transitive = [
            getattr(dep, kernel_type).transitive_files
            for dep in deps
            if hasattr(dep, kernel_type)
        ],
        # The first `main` method is executed in a set of concatenated kernel files.
        # Using topological order makes the parents come before the children,
        # which ensures that the top level implicit library's `main` is used.
        order = "topological",
    )

def _kernel_vm_aspect_impl(target, ctx):
    """The kernel vm action for targets with the dart provider."""

    if not hasattr(target, "dart"):
        return struct()
    dart_ctx = target.dart

    # Libraries without summaries are either one-off odd libraries or are part
    # of the SDK. Don't build kernel files for SDK libraries; they clash with
    # non-SDK libraries.
    if not dart_ctx.strong_summary:
        # Proto libraries use a library without summary on top of a library
        # with summary. In this case we _do_ want kernel.
        if not any([dep.dart.strong_summary for dep in dart_ctx.deps]):
            return struct()

    vm_exclude_srcs = []
    if hasattr(ctx.rule.attr, "vm_exclude_srcs"):
        vm_exclude_srcs += ctx.rule.files.vm_exclude_srcs

    # Filter out excluded srcs
    srcs = [source for source in dart_ctx.dart_srcs if source not in vm_exclude_srcs]

    merged_deps = []
    merged_deps += ctx.rule.attr.deps
    if hasattr(ctx.rule.attr, "_proto_libs_dart"):
        merged_deps += ctx.rule.attr._proto_libs_dart
    transitive_kernel_files = _transitive_kernel_files(merged_deps, "kernel_vm")

    kernel_vm_output = None

    # Some dart_library targets do not have srcs so we shouldn't make a kernel file.
    if srcs:
        kernel_vm_output = ctx.actions.declare_file("%s.vm.dill" % ctx.label.name)
        _make_kernel_file(
            ctx,
            dart_ctx,
            transitive_kernel_files,
            kernel_vm_output,
            srcs,
        )

        # Add the kernel output to the transitive kernel files
        transitive_kernel_files = depset(
            [kernel_vm_output],
            transitive = [transitive_kernel_files],
        )
    return struct(
        kernel_vm = struct(transitive_files = transitive_kernel_files),
    )

kernel_vm_aspect = aspect(
    attr_aspects = [
        "deps",
        # We need to traverse the proto Dart libraries.
        # TODO(grouma) - change name to make this obvious and
        # potentially consistent with other aspects.
        "_proto_libs_dart",
    ],
    attrs = {
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
    },
    implementation = _kernel_vm_aspect_impl,
    required_aspect_providers = ["dart"],
)

"""Normalizes paths to targets which may vary based on the workspace."""

labels = struct(
    package = Label("@bazel_codegen//:bazel_codegen"),
    template = Label("//dart/build_rules/codegen:codegen_template"),
)

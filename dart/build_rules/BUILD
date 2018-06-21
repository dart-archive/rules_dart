load("@bazel_skylib//:skylark_library.bzl", "skylark_library")

package(default_visibility = ["//visibility:public"])

skylark_library(
    name = "core",
    srcs = ["core.bzl"],
    deps = [
        "//dart/build_rules/internal:dart_library",
    ],
)

skylark_library(
    name = "vm",
    srcs = ["vm.bzl"],
    deps = [
        "//dart/build_rules/internal:dart_vm_binary",
        "//dart/build_rules/internal:dart_vm_snapshot",
        "@bazel_skylib//:lib",
    ],
)

skylark_library(
    name = "web",
    srcs = ["web.bzl"],
    deps = [
        ":vm",
        "//dart/build_rules/internal:dart_web_application",
        "//dart/build_rules/internal:ddc",
    ],
)

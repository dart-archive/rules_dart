load("@bazel_skylib//:skylark_library.bzl", "skylark_library")

package(default_visibility = ["//visibility:public"])

skylark_library(
    name = "_archive",
    srcs = ["_archive.bzl"],
)

skylark_library(
    name = "constants",
    srcs = ["constants.bzl"],
)

skylark_library(
    name = "context",
    srcs = ["context.bzl"],
    deps = [
        ":_archive",
        ":constants",
        ":path",
        "//dart/build_rules/common:ddc",
        "//dart/build_rules/common:label",
    ],
)

skylark_library(
    name = "ddc",
    srcs = ["ddc.bzl"],
)

skylark_library(
    name = "label",
    srcs = ["label.bzl"],
)

bzl_library(
    name = "package_spec",
    srcs = ["package_spec.bzl"],
    deps = [
        ":context",
        ":path",
    ],
)

bzl_library(
    name = "kernel",
    srcs = ["kernel.bzl"],
    deps = [
        ":package_spec",
        ":path",
        "//dart/build_rules/internal:common",
    ],
)

# TODO(@Capstan): path -> @bazel_skylib//:lib.bzl paths
skylark_library(
    name = "path",
    srcs = ["path.bzl"],
)

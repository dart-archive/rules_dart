load("@bazel_skylib//:skylark_library.bzl", "skylark_library")

package(default_visibility = ["//visibility:public"])

skylark_library(
    name = "analyze",
    srcs = ["analyze.bzl"],
    deps = [
        ":common",
    ],
)

skylark_library(
    name = "common",
    srcs = ["common.bzl"],
    deps = [
        "//dart/build_rules/common:constants",
        "//dart/build_rules/common:context",
        "//dart/build_rules/common:ddc",
        "//dart/build_rules/common:label",
        "//dart/build_rules/common:path",
    ],
)

skylark_library(
    name = "dart2js",
    srcs = ["dart2js.bzl"],
    deps = [
        ":common",
    ],
)

skylark_library(
    name = "dart_library",
    srcs = ["dart_library.bzl"],
    deps = [
        ":analyze",
        ":common",
        ":ddc",
    ],
)

skylark_library(
    name = "dart_vm_binary",
    srcs = ["dart_vm_binary.bzl"],
    deps = [
        ":common",
        ":dart_vm_snapshot",
    ],
)

skylark_library(
    name = "dart_vm_snapshot",
    srcs = ["dart_vm_snapshot.bzl"],
    deps = [
        ":common",
    ],
)

skylark_library(
    name = "dart_vm_test",
    srcs = ["dart_vm_test.bzl"],
    deps = [
        ":common",
    ],
)

skylark_library(
    name = "dart_web_application",
    srcs = ["dart_web_application.bzl"],
    deps = [
        ":common",
        ":dart2js",
    ],
)

skylark_library(
    name = "ddc",
    srcs = ["ddc.bzl"],
    deps = [
        ":common",
    ],
)

skylark_library(
    name = "pub",
    srcs = ["pub.bzl"],
)

skylark_library(
    name = "sdk",
    srcs = ["sdk.bzl"],
)

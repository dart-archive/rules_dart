load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "stack_trace",
    srcs = [
        "@stack_trace//:stack_trace"
    ],
    license_files = ["@stack_trace//:LICENSE_FILES"],
    pub_pkg_name = "stack_trace",
    deps = [
        "//vendor/path",
    ],
)


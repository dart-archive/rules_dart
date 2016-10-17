load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "stream_channel",
    srcs = [
        "@vendor_stream_channel//:stream_channel"
    ],
    license_files = ["@vendor_stream_channel//:LICENSE_FILES"],
    pub_pkg_name = "stream_channel",
    deps = [
        "//vendor/async",
        "//vendor/stack_trace",
    ],
)

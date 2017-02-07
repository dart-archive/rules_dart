load("//dart/build_rules:core.bzl", "dart_library")
package(default_visibility = ["//visibility:public"])

dart_library(
    name = "server",
    srcs = [
        "bin/server.dart",
    ],
    deps = [
        "@vendor_args//:args",
        "@vendor_path//:path",
        "@vendor_shelf//:shelf",
        "@vendor_shelf_static//:shelf_static",
        "@vendor_watcher//:watcher",
    ],
)

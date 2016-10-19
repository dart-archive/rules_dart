load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "watcher",
    srcs = [
        "@vendor_watcher//:watcher"
    ],
    license_files = ["@vendor_watcher//:LICENSE_FILES"],
    pub_pkg_name = "watcher",
    deps = [
        "//vendor/async",
        "//vendor/collection",
        "//vendor/path",
    ],
)

load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "async",
    srcs = [
        "@vendor_async//:async"
    ],
    license_files = ["@vendor_async//:LICENSE_FILES"],
    pub_pkg_name = "async",
    deps = [
        "//vendor/collection",
    ],
)

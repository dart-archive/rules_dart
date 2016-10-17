load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "csslib",
    srcs = [
        "@vendor_csslib//:csslib"
    ],
    license_files = ["@vendor_csslib//:LICENSE_FILES"],
    pub_pkg_name = "csslib",
    deps = [
        "//vendor/args",
        "//vendor/logging",
        "//vendor/path",
        "//vendor/source_span",
    ],
)

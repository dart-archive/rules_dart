load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "string_scanner",
    srcs = [
        "@string_scanner//:string_scanner"
    ],
    license_files = ["@string_scanner//:LICENSE_FILES"],
    pub_pkg_name = "string_scanner",
    deps = [
        "//vendor/charcode",
        "//vendor/source_span",
    ],
)


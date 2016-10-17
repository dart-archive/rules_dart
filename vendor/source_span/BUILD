load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "source_span",
    srcs = [
        "@vendor_source_span//:source_span"
    ],
    license_files = ["@vendor_source_span//:LICENSE_FILES"],
    pub_pkg_name = "source_span",
    deps = [
        "//vendor/path",
    ],
)

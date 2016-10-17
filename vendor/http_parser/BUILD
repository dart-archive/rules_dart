load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "http_parser",
    srcs = [
        "@vendor_http_parser//:http_parser"
    ],
    license_files = ["@vendor_http_parser//:LICENSE_FILES"],
    pub_pkg_name = "http_parser",
    deps = [
      "//vendor/collection",
      "//vendor/source_span",
      "//vendor/string_scanner",
    ],
)

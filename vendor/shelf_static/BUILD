load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "shelf_static",
    srcs = [
        "@vendor_shelf_static//:shelf_static"
    ],
    license_files = ["@vendor_shelf_static//:LICENSE_FILES"],
    pub_pkg_name = "shelf_static",
    deps = [
        "//vendor/convert",
        "//vendor/http_parser",
        "//vendor/mime",
        "//vendor/path",
        "//vendor/shelf",
    ],
)

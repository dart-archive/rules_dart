load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "convert",
    srcs = [
        "@vendor_convert//:convert"
    ],
    license_files = ["@vendor_convert//:LICENSE_FILES"],
    pub_pkg_name = "convert",
    deps = [
        "//vendor/charcode",
        "//vendor/typed_data",
    ],
)

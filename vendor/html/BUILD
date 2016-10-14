load("//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

dart_library(
    name = "html",
    srcs = [
        "@html//:html"
    ],
    license_files = ["@html//:LICENSE_FILES"],
    pub_pkg_name = "html",
    deps = [
        "//vendor/csslib",
        "//vendor/source_span",
        "//vendor/utf",
    ],
)

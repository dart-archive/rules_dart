package(default_visibility = ["//visibility:public"])

exports_files(["codegen_template"])

filegroup(
    name = "bzl",
    testonly = True,
    srcs = glob(["**/*bzl"]),
    data = ["//dart/build_rules:bzl"],
)

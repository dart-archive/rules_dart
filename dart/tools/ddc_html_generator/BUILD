load("//dart/build_rules:vm.bzl", "dart_vm_binary")

dart_vm_binary(
    name = "ddc_html_generator",
    srcs = [
        "bin/ddc_html_generator.dart",
    ],
    script_file = "bin/ddc_html_generator.dart",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/args",
        "//vendor/html",
        "//vendor/path",
    ],
)

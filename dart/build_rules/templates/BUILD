package(default_visibility = ["//visibility:public"])

filegroup(
    name = "dart_vm_binary",
    srcs = ["dart_vm_binary.sh"],
)

filegroup(
    name = "dart_vm_test_template",
    srcs = select({
        "//dart:coverage_config": [":dart_vm_test_coverage"],
        "//conditions:default": [":dart_vm_test"],
    }),
)

filegroup(
    name = "dart_vm_test",
    srcs = ["dart_vm_test.sh"],
)

filegroup(
    name = "dart_vm_test_coverage",
    srcs = ["dart_vm_test_coverage.sh"],
)

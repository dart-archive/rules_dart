load("//dart/build_rules:core.bzl", "dart_library")
load("//dart/build_rules:vm.bzl","dart_vm_test")
load("//dart/build_rules:code_gen.bzl","dart_code_gen")

package(default_visibility = ["//visibility:public"])

dart_vm_test(
    name = "generate_test",
    srcs = ["test/generate_test.dart"],
    data = [":hello_code_gen"],
    script_file = "test/generate_test.dart",
)

dart_code_gen(
    name = "hello_code_gen",
    generator = "//examples/generate_copyright",
    generator_args = ["--holder=Someone"],
    out_extensions = [".g.dart"],
    srcs = ["lib/hello.dart"],
)

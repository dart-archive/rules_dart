load(
    "//dart/build_rules:vm.bzl",
    "dart_vm_binary",
    "dart_vm_test",
)
load(
    "//examples/hello_genrule:hello_genrule.bzl",
    "hello_gen",
)

package(default_visibility = ["//visibility:public"])

dart_vm_binary(
    name = "generate",
    srcs = ["bin/generate.dart"],
    script_file = "bin/generate.dart",
)

dart_vm_test(
    name = "message_test",
    srcs = ["test/message_test.dart"],
    data = [":generate_message"],
    script_file = "test/message_test.dart",
)

hello_gen(
    name = "generate_message",
    input_file = "test/message.txt",
    output_file = "test/message.dart",
)

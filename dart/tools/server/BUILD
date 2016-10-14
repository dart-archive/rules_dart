load("//dart/build_rules:vm.bzl", "dart_vm_binary")

dart_vm_binary(
    name = "server",
    srcs = [
        "bin/server.dart",
    ],
    script_file = "bin/server.dart",
    deps = [
        "//vendor/async",
        "//vendor/collection",
        "//vendor/path",
    ],
)

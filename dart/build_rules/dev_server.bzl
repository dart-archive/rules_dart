load("//dart/build_rules:vm.bzl", "dart_vm_binary")

def dev_server(name, data=[], deps=[], **kwargs):
  dart_vm_binary(
      name = name,
      srcs = ["@io_bazel_rules_dart//dart/tools/dev_server:bin/server.dart"],
      data = data,
      script_file = "@io_bazel_rules_dart//dart/tools/dev_server:bin/server.dart",
      deps = ["@io_bazel_rules_dart//dart/tools/dev_server:server"] + deps,
      **kwargs
  )

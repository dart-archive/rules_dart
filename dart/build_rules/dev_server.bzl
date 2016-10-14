load("//dart/build_rules:vm.bzl", "dart_vm_binary")

def dev_server(name, data=[], deps=[], **kwargs):
  dart_vm_binary(
      name = name,
      srcs = ["//dart/tools/dev_server:bin/server.dart"],
      data = data,
      script_file = "//dart/tools/dev_server:bin/server.dart",
      deps = ["//dart/tools/dev_server:server"] + deps,
      **kwargs
  )

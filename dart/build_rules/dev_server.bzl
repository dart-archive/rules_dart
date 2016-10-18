load("//dart/build_rules:vm.bzl", "dart_vm_binary")

def dev_server(name, data=[], deps=[], rules_dart_repo_name = "@io_bazel_rules_dart", **kwargs):
  dart_vm_binary(
      name = name,
      srcs = [rules_dart_repo_name + "//dart/tools/dev_server:bin/server.dart"],
      data = data,
      script_file = rules_dart_repo_name + "//dart/tools/dev_server:bin/server.dart",
      deps = [rules_dart_repo_name + "//dart/tools/dev_server:server"] + deps,
      **kwargs
  )

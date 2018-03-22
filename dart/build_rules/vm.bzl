# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Dart rules targeting the Dart VM."""

load(
    "//dart/build_rules/common:dicts.bzl",
    "dicts",
)
load(
    "//dart/build_rules/internal:dart_vm_binary.bzl",
    "internal_dart_vm",
)
load(
    "//dart/build_rules/internal:dart_vm_snapshot.bzl",
    "dart_vm_snapshot_action",
    "dart_vm_snapshot_impl",
)
load("//dart/build_rules/internal:dart_vm_test.bzl", "dart_vm_test_impl")

_dart_vm_binary_attrs = dicts.add(internal_dart_vm.common_attrs, {
    "script_file": attr.label(
        allow_files = True,
        single_file = True,
        mandatory = True,
    ),
    "script_args": attr.string_list(),
    "vm_flags": attr.string_list(),
    "pub_pkg_name": attr.string(default = ""),
    "srcs": attr.label_list(
        allow_files = True,
        mandatory = True,
    ),
    "data": attr.label_list(
        allow_files = True,
        cfg = "data",
    ),
    "deps": attr.label_list(providers = ["dart"]),
    "snapshot": attr.bool(default = True),
})

def _dart_vm_binary_impl(ctx):
  """Implements the dart_vm_binary() rule."""
  runfiles = internal_dart_vm.binary_action(
      ctx,
      script_file = ctx.file.script_file,
      srcs = ctx.attr.srcs,
      deps = ctx.attr.deps,
      data = ctx.attr.data,
      snapshot = ctx.attr.snapshot,
      script_args = ctx.attr.script_args,
      vm_flags = ctx.attr.vm_flags,
      pub_pkg_name = ctx.attr.pub_pkg_name,
  )
  return struct(
      runfiles=runfiles,
  )

dart_vm_binary = rule(
    attrs = _dart_vm_binary_attrs,
    executable = True,
    implementation = _dart_vm_binary_impl,
)

dart_vm_snapshot = rule(
    attrs = _dart_vm_binary_attrs,
    outputs = {"snapshot": "%{name}.snapshot"},
    implementation = dart_vm_snapshot_impl,
)

dart_vm_test = rule(
    attrs = {
        "script_file": attr.label(
            allow_files = True,
            single_file = True,
            mandatory = True,
        ),
        "script_args": attr.string_list(),
        "vm_flags": attr.string_list(),
        "pub_pkg_name": attr.string(default = ""),
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
        "deps": attr.label_list(providers = ["dart"]),
        "_dart_vm": attr.label(
            allow_files = True,
            single_file = True,
            executable = True,
            cfg = "host",
            default = Label("@dart_sdk//:dart_vm"),
        ),
        "_entrypoint_template": attr.label(
            single_file = True,
            default = Label("//dart/build_rules/templates:dart_vm_test_template"),
        ),
    },
    executable = True,
    test = True,
    implementation = dart_vm_test_impl,
)

dart_vm = struct(
    binary_action = internal_dart_vm.binary_action,
    common_attrs = internal_dart_vm.common_attrs,
)

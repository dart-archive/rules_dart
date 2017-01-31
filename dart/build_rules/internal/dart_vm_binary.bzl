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

load(":common.bzl", "collect_files", "make_dart_context", "package_spec_action")
load(":dart_vm_snapshot.bzl", "dart_vm_snapshot_action")

def dart_vm_binary_action(
    ctx,
    script_file,
    srcs,
    deps,
    data = [],
    snapshot = True,
    script_args = [],
    vm_flags = [],
    pub_pkg_name = ""):
  dart_ctx = make_dart_context(
      ctx.label,
      srcs = srcs,
      data = data,
      deps = deps,
      pub_pkg_name = pub_pkg_name)

  if snapshot:
    out_snapshot = ctx.new_file(ctx.label.name + ".snapshot")
    dart_vm_snapshot_action(
        ctx = ctx,
        dart_ctx = dart_ctx,
        output = out_snapshot,
        vm_flags = vm_flags,
        script_file = script_file,
        script_args = script_args,
    )
    script_file = out_snapshot

  # Emit package spec.
  package_spec = ctx.new_file(ctx.label.name + ".packages")
  package_spec_action(
      ctx = ctx,
      dart_ctx = dart_ctx,
      output = package_spec,
  )

  # Emit entrypoint script.
  ctx.template_action(
      output = ctx.outputs.executable,
      template = ctx.file._entrypoint_template,
      executable = True,
      substitutions = {
          "%workspace%": ctx.workspace_name,
          "%dart_vm%": ctx.executable._dart_vm.short_path,
          "%package_spec%": package_spec.short_path,
          "%vm_flags%": " ".join(vm_flags),
          "%script_file%": script_file.short_path,
          "%script_args%": " ".join(script_args),
      },
  )

  # Compute runfiles.
  all_srcs, all_data = collect_files(dart_ctx)
  runfiles_files = all_data + all_srcs + [
      ctx.executable._dart_vm,
      ctx.outputs.executable,
      package_spec,
  ]
  if snapshot:
    runfiles_files += [out_snapshot]

  return ctx.runfiles(
      files = list(runfiles_files),
      collect_data = True,
  )

_default_binary_attrs = {
    "_dart_vm": attr.label(
        allow_files = True,
        single_file = True,
        executable = True,
        cfg = "host",
        default = Label("//dart/build_rules/ext:dart_vm"),
    ),
    "_entrypoint_template": attr.label(
        single_file = True,
        default = Label("//dart/build_rules/templates:dart_vm_binary"),
    ),
}

def dart_vm_binary_defaults(attrs):
  """Adds attributes with defaults necessary to run dart_vm_binary_action."""
  return dict(_default_binary_attrs.items() + attrs.items())

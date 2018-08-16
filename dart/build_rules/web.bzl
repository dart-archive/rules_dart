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

"""Dart rules targeting web clients."""

load(
    "//dart/build_rules/internal:dart_web_application.bzl",
    "dart_web_application_impl",
    "dart_web_application_outputs",
)
load(
    "//dart/build_rules/internal:ddc.bzl",
    "dart_ddc_bundle_impl",
    "dart_ddc_bundle_outputs",
)
load(":vm.bzl", "dart_vm_binary")

dart_web_application = rule(
    attrs = {
        "script_file": attr.label(
            allow_files = True,
            single_file = True,
            mandatory = True,
        ),
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
        "deps": attr.label_list(providers = ["dart"]),
        "create_packages_dir": attr.bool(default = True),
        "output_js": attr.string(),
        # compiler flags
        "checked": attr.bool(default = False),
        "csp": attr.bool(default = False),
        "dump_info": attr.bool(default = False),
        "emit_tar": attr.bool(default = True),
        "fast_startup": attr.bool(default = False),
        "minify": attr.bool(default = True),
        "preserve_uris": attr.bool(default = False),
        "trust_primitives": attr.bool(default = False),
        "trust_type_annotations": attr.bool(default = False),
        # tools
        "_dart2js": attr.label(
            allow_files = True,
            single_file = True,
            executable = True,
            cfg = "host",
            default = Label("@dart_sdk//:dart2js"),
        ),
        "_dart2js_support": attr.label(
            allow_files = True,
            default = Label("@dart_sdk//:dart2js_support"),
        ),
        "_dart2js_helper": attr.label(
            allow_files = True,
            single_file = True,
            executable = True,
            cfg = "host",
            default = Label("//dart/build_rules/tools:dart2js_helper"),
        ),
    },
    outputs = dart_web_application_outputs,
    implementation = dart_web_application_impl,
)

dart_ddc_bundle = rule(
    attrs = {
        "check_duplicate_srcs": attr.bool(default = False),
        "entry_library": attr.string(),
        "entry_module": attr.label(providers = ["ddc"]),
        "input_html": attr.label(allow_files = True),
        "include_test": attr.bool(default = False),
        "output_dir": attr.string(default = ""),
        "output_html": attr.string(default = ""),
        "_ddc_concat": attr.label(
            single_file = True,
            executable = True,
            cfg = "host",
            default = Label("//dart/build_rules/tools:ddc_concat"),
        ),
        "_ddc_html_generator": attr.label(
            single_file = True,
            executable = True,
            cfg = "host",
            default = Label("//dart/tools/ddc_html_generator"),
        ),
        "_ddc_support": attr.label(
            default = Label("@dart_sdk//:ddc_support"),
        ),
        "_sdk_summary": attr.label(
            default = Label("@dart_sdk//:sdk_summary"),
            allow_single_file = True,
        ),
        "_js_pkg": attr.label(
            default = Label("@vendor_js//:js"),
        ),
    },
    outputs = dart_ddc_bundle_outputs,
    implementation = dart_ddc_bundle_impl,
)

# Skylark macro for creating a development server to serve an application.
#
# You should always pass a `name` (forwarded to dart_vm_binary), as well as a
# `data` argument. The `data` represents the target(s) you want the server to be
# able to serve.
#
# If you have renamed the rules_dart_repo, you will need to provide that name
# via the `rules_dart_repo_name` argument.
def dev_server(
        rules_dart_repo_name = "@io_bazel_rules_dart",
        **kwargs):
    dart_vm_binary(
        srcs = [rules_dart_repo_name + "//dart/tools/dev_server:bin/server.dart"],
        script_file = rules_dart_repo_name + "//dart/tools/dev_server:bin/server.dart",
        deps = [rules_dart_repo_name + "//dart/tools/dev_server:server"],
        **kwargs
    )

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

"""Dart rules shared across deployment platforms."""

load("//dart/build_rules/internal:dart_library.bzl", "dart_library_impl")

dart_library = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
        "enable_ddc": attr.bool(default = True),
        "enable_summaries": attr.bool(default = True),
        "pub_pkg_name": attr.string(default = ""),
        "deps": attr.label_list(providers = ["dart"]),
        "force_ddc_compile": attr.bool(default = False),
        "license_files": attr.label_list(allow_files = True),
        "web_exclude_srcs": attr.label_list(allow_files = True),
        "_analyzer": attr.label(
            default = Label("@dart_sdk//:analyzer"),
            executable = True,
            cfg = "host",
        ),
        "_dev_compiler": attr.label(
            default = Label("@dart_sdk//:dev_compiler"),
            executable = True,
            cfg = "host",
        ),
    },
    implementation = dart_library_impl,
)

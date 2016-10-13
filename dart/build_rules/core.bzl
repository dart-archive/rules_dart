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

load(
    ":internal.bzl",
    "assert_third_party_licenses",
    "has_dart_sources",
    "make_dart_context",
)
load(":analyze.bzl", "summary_action")

def _dart_library_impl(ctx):
  """Implements the dart_library() rule."""
  assert_third_party_licenses(ctx)

  strong_summary = ctx.outputs.strong_summary
  _has_dart_sources = has_dart_sources(ctx.files.srcs)

  dart_ctx = make_dart_context(ctx.label,
                               srcs=ctx.files.srcs,
                               data=ctx.files.data,
                               deps=ctx.attr.deps,
                               strong_summary=strong_summary,)

  if not _has_dart_sources:
    ctx.file_action(
        output=strong_summary,
        content=("// empty summary, package %s has no dart sources" %
                 ctx.label.name))
  else:
    summary_action(ctx, dart_ctx)

  return struct(
      dart=dart_ctx,
  )

def _dart_library_outputs():
  """Returns the outputs of a Dart library rule.

  Dart library targets emit the following outputs:

  * name.api.ds: the strong-mode summary from dart analyzer (API only), if specified.

  Returns:
    a dict of types of outputs to their respective file suffixes
  """
  outs = {
    "strong_summary": "%{name}." + "api.ds"
  }

  return outs

_dart_library_attrs = {
    "srcs": attr.label_list(
        allow_files = True,
        mandatory = True,
    ),
    "data": attr.label_list(
        allow_files = True,
        cfg = "data",
    ),
    "deps": attr.label_list(providers = ["dart"]),
    "license_files": attr.label_list(allow_files = True),
    "_analyzer": attr.label(
        default = Label("@dart_linux_x86_64//:analyzer"),
        executable = True,
        cfg = "host",
    ),
}

dart_library = rule(
    attrs = _dart_library_attrs,
    outputs = _dart_library_outputs,
    implementation = _dart_library_impl,
)

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

"""A set of BUILD rules that facilitate using or building on "pub"."""

def _pub_repository_impl(repository_ctx):
  package = repository_ctx.attr.package
  version = repository_ctx.attr.version

  repository_ctx.download_and_extract(
      "https://storage.googleapis.com/pub.dartlang.org/packages/%s-%s.tar.gz" % (package, version),
      repository_ctx.attr.output,
  )

  repository_ctx.file(
      "%s/BUILD" % (repository_ctx.attr.output),
"""
package(default_visibility = ["//visibility:public"])

filegroup(name = "%s", srcs=glob(["lib/**"]))
filegroup(name = "LICENSE_FILES", srcs=["LICENSE"])
""" % package,
  )

pub_repository = repository_rule(
    implementation = _pub_repository_impl,
    attrs = {
        "name": attr.string(),
        "output": attr.string(),
        "package": attr.string(mandatory=True),
        "version": attr.string(mandatory=True),
    },
)

def pub_repositories():
  pub_repository(
      name = "vendor_args",
      output = ".",
      package = "args",
      version = "0.13.6",
  )

  pub_repository(
      name = "vendor_async",
      output = ".",
      package = "async",
      version = "1.11.2",
  )

  pub_repository(
      name = "vendor_charcode",
      output = ".",
      package = "charcode",
      version = "1.1.0",
  )

  pub_repository(
      name = "vendor_collection",
      output = ".",
      package = "collection",
      version = "1.9.1",
  )

  pub_repository(
      name = "vendor_convert",
      output = ".",
      package = "convert",
      version = "2.0.1",
  )

  pub_repository(
      name = "vendor_csslib",
      output = ".",
      package = "csslib",
      version = "0.13.2",
  )

  pub_repository(
      name = "vendor_html",
      output = ".",
      package = "html",
      version = "0.13.0",
  )

  pub_repository(
      name = "vendor_http_parser",
      output = ".",
      package = "http_parser",
      version = "3.0.3",
  )

  pub_repository(
      name = "vendor_logging",
      output = ".",
      package = "logging",
      version = "0.11.3+1",
  )

  pub_repository(
      name = "vendor_mime",
      output = ".",
      package = "mime",
      version = "0.9.3",
  )

  pub_repository(
      name = "vendor_path",
      output = ".",
      package = "path",
      version = "1.4.0",
  )

  pub_repository(
      name = "vendor_shelf",
      output = ".",
      package = "shelf",
      version = "0.6.5+3",
  )

  pub_repository(
      name = "vendor_shelf_static",
      output = ".",
      package = "shelf_static",
      version = "0.2.4",
  )

  pub_repository(
      name = "vendor_source_span",
      output = ".",
      package = "source_span",
      version = "1.2.3",
  )

  pub_repository(
      name = "vendor_stack_trace",
      output = ".",
      package = "stack_trace",
      version = "1.6.8",
  )

  pub_repository(
      name = "vendor_stream_channel",
      output = ".",
      package = "stream_channel",
      version = "1.5.0",
  )

  pub_repository(
      name = "vendor_string_scanner",
      output = ".",
      package = "string_scanner",
      version = "1.0.0",
  )

  pub_repository(
      name = "vendor_typed_data",
      output = ".",
      package = "typed_data",
      version = "1.1.3",
  )

  pub_repository(
      name = "vendor_utf",
      output = ".",
      package = "utf",
      version = "0.9.0+3",
  )

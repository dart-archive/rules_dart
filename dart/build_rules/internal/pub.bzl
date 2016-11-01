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
    attrs = {
        "name": attr.string(),
        "output": attr.string(),
        "package": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
    implementation = _pub_repository_impl,
)

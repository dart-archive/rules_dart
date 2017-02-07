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

_pub_uri = "https://storage.googleapis.com/pub.dartlang.org/packages"

"""A set of BUILD rules that facilitate using or building on "pub"."""

def _pub_repository_impl(repository_ctx):
  package = repository_ctx.attr.package
  version = repository_ctx.attr.version

  repository_ctx.download_and_extract(
      "%s/%s-%s.tar.gz" % (_pub_uri, package, version),
      repository_ctx.attr.output,
  )


  pub_deps = repository_ctx.attr.pub_deps
  bazel_deps = ["\"@vendor_%s//:%s\"" % (dep, dep) for dep in pub_deps]
  deps = ",\n".join(bazel_deps)

  repository_ctx.file(
      "%s/BUILD" % (repository_ctx.attr.output),
"""
load("@io_bazel_rules_dart//dart/build_rules:core.bzl", "dart_library")

package(default_visibility = ["//visibility:public"])

filegroup(name = "LICENSE_FILES", srcs=["LICENSE"])

dart_library(
    name = "%s",
    srcs = glob(["lib/**"]),
    license_files = ["LICENSE"],
    pub_pkg_name = "%s",
    deps = [
        %s
    ],
)

""" % (package, package, deps),
  )

pub_repository = repository_rule(
    attrs = {
        "output": attr.string(),
        "package": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "pub_deps": attr.string_list(default = []),
    },
    implementation = _pub_repository_impl,
)

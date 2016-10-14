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

"""Repositories for Dart."""

_DART_SDK_BUILD_FILE = """
package(default_visibility = [ "//visibility:public" ])

filegroup(
  name = "dart_vm",
  srcs = ["dart-sdk/bin/dart"],
)

filegroup(
  name = "analyzer",
  srcs = ["dart-sdk/bin/dartanalyzer"],
)

filegroup(
  name = "dart2js",
  srcs = ["dart-sdk/bin/dart2js"],
)

filegroup(
  name = "dart2js_support",
  srcs = glob([
      "dart-sdk/bin/dart",
      "dart-sdk/bin/snapshots/dart2js.dart.snapshot",
      "dart-sdk/lib/**",
  ]),
)

filegroup(
  name = "dev_compiler",
  srcs = ["dart-sdk/bin/dartdevc"],
)

filegroup(
  name = "pub",
  srcs = ["dart-sdk/bin/pub"],
)

filegroup(
  name = "pub_support",
  srcs = glob([
      "dart-sdk/version",
      "dart-sdk/bin/dart",
      "dart-sdk/bin/snapshots/pub.dart.snapshot",
  ]),
)

"""

def dart_repositories():
  native.new_http_archive(
      name = "dart_linux_x86_64",
      # WHEN UPDATING THE SDK YOU MUST ALSO UPDATE /dart/build_rules/ddc_support
      # TODO: Use the ddc support files from the sdk once available.
      #       See https://github.com/dart-lang/sdk/issues/27001
      url = "https://storage.googleapis.com/dart-archive/channels/dev/release/1.20.0-dev.10.3/sdk/dartsdk-linux-x64-release.zip",
      sha256 = "dcbf41b5ea0f577aff098ed5d1dc62cc744be1311ce70e522eeccd7f2db9c282",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

  native.new_http_archive(
      name = "dart_darwin_x86_64",
      url = "https://storage.googleapis.com/dart-archive/channels/dev/release/1.20.0-dev.10.3/sdk/dartsdk-macos-x64-release.zip",
      sha256 = "8b38cc2f23ce3003d69e87285eab3f1a95ee5f6576deca80a22ad0469c30a652",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

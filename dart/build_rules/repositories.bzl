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
    name = "ddc_support",
    srcs = glob(["dart-sdk/lib/_internal/dev_compiler/legacy/*.*"]),
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

filegroup(
  name = "sdk_summaries",
  srcs = ["dart-sdk/lib/_internal/strong.sum"],
)

"""

def dart_repositories():
  native.new_http_archive(
      name = "dart_linux_x86_64",
      url = "https://storage.googleapis.com/dart-archive/channels/be/raw/141823/sdk/dartsdk-linux-x64-release.zip",
      sha256 = "e74e1aa31dcb5ae4822247836760beb252e2f08adb7da1a86b1cd59c5e280acb",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

  native.new_http_archive(
      name = "dart_darwin_x86_64",
      url = "https://storage.googleapis.com/dart-archive/channels/be/raw/141823/sdk/dartsdk-macos-x64-release.zip",
      sha256 = "21e470aad6ca3e58b61474fd681897a31fb0909708ee63644e05bb8e668db63e",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

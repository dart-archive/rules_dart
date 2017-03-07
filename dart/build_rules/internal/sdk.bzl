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
"""A repository rule to download the Dart SDK."""

_BUILD_FILE = """
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
    srcs = glob(["dart-sdk/lib/dev_compiler/legacy/*.*"]),
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

filegroup(
    name = "lib_files_no_summaries",
    srcs = glob([
        "dart-sdk/lib/**/*.dart",
        "dart-sdk/lib/dart_client.platform",
        "dart-sdk/lib/dart_shared.platform",
        "dart-sdk/version",
    ]),
)

filegroup(
    name = "lib_files",
    srcs = glob([
        ":lib_files_no_summaries",
        ":sdk_summaries",
    ]),
)

"""

_hosted_prefix = "https://storage.googleapis.com/dart-archive/channels/stable/release"
_linux_file = "dartsdk-linux-x64-release.zip"
_mac_file = "dartsdk-macos-x64-release.zip"

_version = "1.22.0"
_linux_sha = "f474bdd9f9bbd5811f53ef07ad8109cf0abab58a9438ac3663ef41e8d741a694"
_mac_sha = "6f5e3ddfa32666f72392b985b78a7ccc8c507285c6d9ce59bdadd58de45ef343"


def _sdk_repository_impl(repository_ctx):
  """Downloads the appropriate SDK for the current OS."""
  os_name = repository_ctx.os.name

  file_name = False

  if "linux" in os_name:
    file_name = _linux_file
    sha = _linux_sha
  elif "mac os" in os_name:
    file_name = _mac_file
    sha = _mac_sha

  if not file_name:
    fail('Cannot find SDK for OS: %s' % os_name)

  repository_ctx.download_and_extract(
      url = "%s/%s/sdk/%s" % (_hosted_prefix, _version, file_name),
      sha256 = sha,
  )
  repository_ctx.file("BUILD", _BUILD_FILE)

sdk_repository = repository_rule(
    implementation = _sdk_repository_impl,
)

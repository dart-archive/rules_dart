load("//dart/build_rules/internal:pub.bzl", "pub_repository")

"""Required Repositories for Dart Build Rules."""
def dart_repositories():
  _sdk_repositories()
  _pub_repositories()

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

"""

def _sdk_repositories():
  native.new_http_archive(
      name = "dart_linux_x86_64",
      url = "https://storage.googleapis.com/dart-archive/channels/stable/release/1.21.0/sdk/dartsdk-linux-x64-release.zip",
      sha256 = "71c18fefa005017a34c2381872c3b189e0a3983ff4a510821d9e862e6e2a4e91",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

  native.new_http_archive(
      name = "dart_darwin_x86_64",
      url = "https://storage.googleapis.com/dart-archive/channels/stable/release/1.21.0/sdk/dartsdk-macos-x64-release.zip",
      sha256 = "97a7adf5c4c291fdf020613392455766ac30d2de139c8d3334e001a7cfc44084",
      build_file_content = _DART_SDK_BUILD_FILE,
  )

def _pub_repositories():
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
      name = "vendor_js",
      output = ".",
      package = "js",
      version = "0.6.1",
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

  pub_repository(
      name = "vendor_watcher",
      output = ".",
      package = "watcher",
      version = "0.9.7+3",
  )

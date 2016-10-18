load("//dart/build_rules:core.bzl", "dart_library")
load("//dart/build_rules:ddc.bzl", "dart_ddc_bundle")
load("//dart/build_rules:web.bzl", "dart_web_application")
load("//dart/build_rules:dev_server.bzl", "dev_server")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # BSD

dart_library(
    name = "web_app_lib",
    srcs = glob(["lib/**"]),
)

genrule(
    name = "gen_lib",
    cmd = """echo 'String generatedFunc() => "generated";' > $@""",
    outs = ["web/generated.dart"],
)

dart_library(
    name = "web_app",
    srcs = glob(["web/**"]) + [":gen_lib"],
    deps = [":web_app_lib"],
)

dart_ddc_bundle(
    name = "ddc_bundle",
    entry_library = "web/main.dart",
    entry_module = ":web_app",
    input_html = "web/index.html",
    output_dir = "web",
)

# To run, do the following:
#
#   - open up a terminal
#   - run `bazel build examples/web_app:ddc_dev_server`
#   - run `bazel-bin/examples/web_app/ddc_dev_server` to start the server
#   - load http://localhost:8080/examples/web_app/web/ddc_bundle.html in chrome
#
# Rerun `bazel build examples/web_app:ddc_dev_server` in a different terminal
# whenever you make a change to see the updates!
dev_server(
    name = "ddc_dev_server",
    data = [
      ":ddc_bundle",
    ],
    rules_dart_repo_name = "",
)

dart_web_application(
    name = "js_debug",
    srcs = [],
    script_file = "web/main.dart",
    checked = True,
    minify = False,
    dump_info = True,
    deps = [":web_app"],
)

dart_web_application(
    name = "js_release",
    srcs = [],
    script_file = "web/main.dart",
    deps = [
        ":web_app",
        "//examples/hello_lib",
    ],
)

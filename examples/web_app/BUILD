load("//dart/build_rules:core.bzl", "dart_library")
load("//dart/build_rules:ddc.bzl", "dart_ddc_bundle")
load("//dart/build_rules:web.bzl", "dart_web_application")

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
)

dart_web_application(
    name = "js_debug",
    srcs = [],
    script_file = "web/main.dart",
    deferred_lib_count = 1,
    checked = True,
    minify = False,
    dump_info = True,
    deps = [":web_app"],
)

dart_web_application(
    name = "js_release",
    srcs = [],
    script_file = "web/main.dart",
    deferred_lib_count = 1,
    deps = [
        ":web_app",
        "//examples/hello_lib",
    ],
)

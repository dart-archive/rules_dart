package(default_visibility = ["//visibility:public"])

alias(
    name = "dart_vm",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:dart_vm",
        "//dart:k8": "@dart_linux_x86_64//:dart_vm",
    }),
)

alias(
    name = "dart2js",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:dart2js",
        "//dart:k8": "@dart_linux_x86_64//:dart2js",
    }),
)

alias(
    name = "dart2js_support",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:dart2js_support",
        "//dart:k8": "@dart_linux_x86_64//:dart2js_support",
    }),
)

alias(
    name = "dart_analyzer",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:analyzer",
        "//dart:k8": "@dart_linux_x86_64//:analyzer",
    }),
)

alias(
    name = "dev_compiler",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:dev_compiler",
        "//dart:k8": "@dart_linux_x86_64//:dev_compiler",
    }),
)

alias(
    name = "ddc_support",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:ddc_support",
        "//dart:k8": "@dart_linux_x86_64//:ddc_support",
    }),
)

alias(
    name = "sdk_summaries",
    actual = select({
        "//dart:darwin": "@dart_darwin_x86_64//:sdk_summaries",
        "//dart:k8": "@dart_linux_x86_64//:sdk_summaries",
    }),
)

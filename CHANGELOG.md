## 0.2.2 - unreleased

* Updated to latest Dart SDK dev release - `1.21.0-dev.3.0`.
* Fixes to support bazel `0.4.0` – but only with sandbox turned off.

## 0.2.1

* Updated to latest Dart SDK dev release - `1.21.0-dev.2.0`.

## 0.2.0

**Breaking Change**: Re-organization of the build rules:

*  `dart_ddc_bundle` moved into `dart/build_rules/web.bzl`.
*  `dev_server` moved into `dart/build_rules/web.bzl`.
*  `pub_repositories` has been moved into `dart_repositories`.
*  `dart/build_rules/pub.bzl` no longer exists.

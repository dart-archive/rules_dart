## 0.5.0-dev

* **Breaking:** Drop deprecated `in_extension` and `out_extensions` arguments in
  favor of `build_extensions`.
* Add platform support in `make_dart_context`.
* Update to work with bazel 0.9.0 and stop using the deprecated `set`
  constructor.
* `dart_codegen_action` now forces support for all platform.
* **Breaking:** In `make_dart_context`, `srcs` and `data` are now list of `Target` instead of list of `File`. A new `generated_srcs` parameter exists for source files that are generated and thus have no associated target. The resulting struct now has its `transitive_*` fields defined like so:
  ```python
  struct(
      ...
      transitive_srcs = struct(
          targets = {<label_name>: <target>},
          files = <depset>,
      ),
      transitive_dart_srcs = struct(
          files = <depset>,
      ),
      transitive_data = struct(
          targets = {<label_name>: <target>},
          files = <depset>,
      ),
      transitive_deps = struct(
          targets = {<label_name>: <target>},
      ),
      transitive_archives = struct(
          files = <depset>,
      ),
  )
  ```

## 0.4.10

* Only add srcs to Dart archives.
* Pass new build-extension style argument to `_bazel_codegen`
* Add `build_extensions` argument to `dart_codegen_rule` to replace the separate
  input and output extension arguments.

## 0.4.9

* Don't gzip Dart archives.
* Explicitly use filename when filtering files.

## 0.4.8

* Add utilities for Dart archives. 

## 0.4.7

* Add support for build time --define arguments to codegen binaries

## 0.4.6

* Include non-lib srcs from dependencies in the same package as inputs during
  codegen with summaries.

## 0.4.5

* Don't include transitive srcs from targets with the "dart" provider in the
  forced_deps argument of codegen rules.

## 0.4.4

* Disallow overriding extensions at usage of codegen rules. Extension behavior
  is an attribute of the codegen_binary.

## 0.4.3

* Bug Fix: Allow `select` as argument to use_resolver in dart_codegen_binary
* Bug Fix: Update to latest dev sdk to get an analyzer worker mode fix.

## 0.4.2

* Add flag `--define=DART_CODEGEN_ASYNC_STACK_TRACE=` for use when debugging
  exceptions in a `Builder`
* Correct a case where use_summaries was not correctly defaulted when
  use_resolver was passed a `select`.
* Add a local_sdk argument to dart_repositories to allow overriding the SDK
  download

## 0.4.1

* Upgrade to Dart 1.22
* Allow generating files for external packages

## 0.4.0

* Update to the way `vendor_` packages are handled. This is a breaking change
  for repositories with manually created `pub_repository` rules.

## 0.3.0

* Added dart_codegen_rule and dart_codegen_binary rules to enabled code
  generation. These rules can only be used alongside bazel_codegen
* Upgrade to Dart 1.21

### Breaking

* Remove old dart_code_gen build rule which was never supported

## 0.2.3

* enabled_ddc argument to dart_library rules allows disabling DDC for libraries
  that don't run on the web.

## 0.2.2

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

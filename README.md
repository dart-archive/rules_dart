# Dart rules

**WARNING** These are in active development and are *not* production-ready.
Expect frequent breaking changes. The only way these rules should be used is
with automatically generated BUILD files which should not be checked in since
they will not be stable across versions of `rules_dart`.

## Overview

These build rules are used for building [Dart][] projects with Bazel. To use the
Dart rules see [bazelify][].

[Dart]: https://dartlang.org
[bazelify]: https://github.com/dart-lang/bazel

## Rules

  * dart\_library
  * dart\_vm\_binary
  * dart\_vm\_snapshot
  * dart\_vm\_test
  * dart\_web\_application
  * dart\_web\_test


## Core rules

`dart_library`: Declares a collection of Dart sources and data and their
dependencies.


## VM rules

`dart_vm_binary`: Builds an executable bundle that runs a script or snapshot on
the Dart VM.

`dart_vm_snapshot`: Builds a VM snapshot of a Dart script. **WARNING** Snapshot
files are *not* guaranteed to be compatible across VM releases.

`dart_vm_test`: Builds a test that will be executed on the Dart VM.


## Web rules

`dart_web_application`: Compiles the specified script to JavaScript.

`dart_web_test`: Builds a test that will be executed in the browser.

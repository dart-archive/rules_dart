import 'dart:convert' show LineSplitter;
import 'dart:io' show Process, ProcessResult;

import 'package:test/test.dart';

main() {
  setUpAll(() {
    var result = _bazel(['version']);
    print(_indent(result.stdout));

    print(_indent('Cleaning...'));
    _bazel(['clean']);
  });

  test('Building a library and some tests...', () {
    var result = _bazel(['build', 'examples/hello_lib:all']);
    if (!result.stderr.contains('Found 3 targets')) {
      _fail(
          'Error: `bazel build examples/hello_lib:all` did not find 3 targets:',
          result);
    }
  });

  test('Testing the passing test...', () {
    var result = _bazel(['test', 'examples/hello_lib:passing_test']);
    if (!new RegExp(r'//examples/hello_lib:passing_test\s+PASSED')
            .hasMatch(result.stdout) ||
        !new RegExp(r'Executed 1 out of 1 test: 1 test passes.')
            .hasMatch(result.stdout)) {
      _fail('Error: `bazel test examples/hello_lib:passing_test` did not pass!',
          result);
    }
  });

  test('Testing the failing test...', () {
    var result = _bazel(['test', 'examples/hello_lib:failing_test'],
        expectedExitCode: 3);
    if (!new RegExp(r'//examples/hello_lib:failing_test\s+FAILED')
            .hasMatch(result.stdout) ||
        !new RegExp(r'Executed 1 out of 1 test: 1 fails locally.')
            .hasMatch(result.stdout)) {
      _fail('Error: `bazel test examples/hello_lib:failing_test` did not fail!',
          result);
    }
  });

  test('Building some vm_binaries...', () {
    var result = _bazel(['build', 'examples/hello_bin:all']);
    if (!result.stderr.contains('Found 4 targets')) {
      _fail(
          'Error: `bazel build examples/hello_bin:all` did not find 4 targets:',
          result);
    }
  });

  for (var target in ['hello_bin', 'nested_bin']) {
    test('Running vm_binary :$target...', () {
      var result = _bazel(['run', 'examples/hello_bin:$target']);
      if (!result.stdout.contains('Hello, world!') ||
          !result.stdout.contains('0 arguments: []')) {
        _fail(
            'Error: `bazel run examples/hello_bin:$target` did not print correctly:',
            result);
      }

      print('Running vm_binary :$target -- arg1 arg2...');
      result =
          _bazel(['run', 'examples/hello_bin:$target', '--', 'arg1', 'arg2']);
      if (!result.stdout.contains('Hello, world!') ||
          !result.stdout.contains('2 arguments: [arg1, arg2]')) {
        _fail(
            'Error: `bazel run examples/hello_bin:$target` did not print correctly:',
            result);
      }
    });
  }

  for (var target in ['hello_bin_checked', 'hello_bin_snapshot']) {
    test('Running vm_binary :$target...', () {
      var result = _bazel(['run', 'examples/hello_bin:$target']);
      if (!result.stdout.contains('Hello, world!') ||
          !result.stdout.contains('2 arguments: [foo, bar]')) {
        _fail(
            'Error: `bazel run examples/hello_bin:$target` did not print correctly:',
            result);
      }
    });
  }

  test('Building some dart_web_binaries...', () {
    var result = _bazel(['build', 'examples/web_app:all']);
    if (!result.stderr.contains('Found 7 targets')) {
      print(_indent(result.stderr));
      fail('Error: `bazel build examples/web_app:all` did not find 7 targets:');
    }
  });

  test('Testing the genrule test...', () {
    var result = _bazel(['test', 'examples/hello_genrule:message_test']);
    if (!new RegExp(r'//examples/hello_genrule:message_test\s+PASSED')
            .hasMatch(result.stdout) ||
        !new RegExp(r'Executed 1 out of 1 test: 1 test passes.')
            .hasMatch(result.stdout)) {
      _fail(
          'Error: `bazel test examples/hello_genrule:message_test` did not pass!',
          result);
    }
  });
}

void _fail(String message, ProcessResult result) {
  fail([message, _indent(result.stdout), _indent(result.stderr)].join('\n'));
}

ProcessResult _bazel(List<String> args, {int expectedExitCode: 0}) {
  var command = args.first;

  var localArgs = ['--bazelrc=/dev/null', command, '--noshow_progress'];
  if (command != 'version') {
    localArgs.add('--spawn_strategy=standalone');
  }
  localArgs.addAll(args.skip(1));

  var result = Process.runSync('bazel', localArgs);

  expect(result.exitCode, expectedExitCode,
      reason: [
        "Did not get the expected exit code",
        _indent(result.stdout),
        _indent(result.stderr)
      ].join('\n'));

  return result;
}

String _indent(String s) =>
    LineSplitter.split(s).map((line) => '    $line').join('\n');

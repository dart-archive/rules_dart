import 'dart:io';

main() {
  var result = bazel(['version']);
  print(result.stdout);

  print('Cleaning...');
  result = bazel(['clean']);

  testBuildLibraryAndTests();
  testPassingTest();
  testFailingTest();
  testBuildVmBinary();
  testRunVmBinary();
  testBuildDartWebBinary();
  testGenruleTest();

  print('\nPASS');
}

void testBuildLibraryAndTests() {
  print('Building a library and some tests...');
  var result = bazel(['build', 'examples/hello_lib:all']);
  if (!result.stderr.contains('Found 3 targets')) {
    print(
        'Error: `bazel build examples/hello_lib:all` did not find 3 targets:');
    print(indent(result.stderr));
    exit(1);
  }
}

void testPassingTest() {
  print('Testing the passing test...');
  var result = bazel(['test', 'examples/hello_lib:passing_test']);
  if (!new RegExp(r'//examples/hello_lib:passing_test\s+PASSED')
          .hasMatch(result.stdout) ||
      !new RegExp(r'Executed 1 out of 1 test: 1 test passes.')
          .hasMatch(result.stdout)) {
    print('Error: `bazel test examples/hello_lib:passing_test` did not pass!');
    print(indent(result.stdout));
    exit(1);
  }
}

void testFailingTest() {
  print('Testing the failing test...');
  var result =
      bazel(['test', 'examples/hello_lib:failing_test'], expectedExitCode: 3);
  if (!new RegExp(r'//examples/hello_lib:failing_test\s+FAILED')
          .hasMatch(result.stdout) ||
      !new RegExp(r'Executed 1 out of 1 test: 1 fails locally.')
          .hasMatch(result.stdout)) {
    print('Error: `bazel test examples/hello_lib:failing_test` did not fail!');
    print(indent(result.stdout));
    print(indent(result.stderr));
    exit(1);
  }
}

void testBuildVmBinary() {
  print('Building some vm_binaries...');
  var result = bazel(['build', 'examples/hello_bin:all']);
  if (!result.stderr.contains('Found 4 targets')) {
    print(
        'Error: `bazel build examples/hello_bin:all` did not find 4 targets:');
    print(indent(result.stderr));
    exit(1);
  }
}

void testRunVmBinary() {
  for (var target in ['hello_bin', 'nested_bin']) {
    print('Running vm_binary :$target...');
    var result = bazel(['run', 'examples/hello_bin:$target']);
    if (!result.stdout.contains('Hello, world!') ||
        !result.stdout.contains('0 arguments: []')) {
      print(
          'Error: `bazel run examples/hello_bin:$target` did not print correctly:');
      print(indent(result.stdout));
      exit(1);
    }

    print('Running vm_binary :$target -- arg1 arg2...');
    result = bazel(['run', 'examples/hello_bin:$target', '--', 'arg1', 'arg2']);
    if (!result.stdout.contains('Hello, world!') ||
        !result.stdout.contains('2 arguments: [arg1, arg2]')) {
      print(
          'Error: `bazel run examples/hello_bin:$target` did not print correctly:');
      print(indent(result.stdout));
      exit(1);
    }
  }

  for (var target in ['hello_bin_checked', 'hello_bin_snapshot']) {
    print('Running vm_binary :$target...');
    var result = bazel(['run', 'examples/hello_bin:$target']);
    if (!result.stdout.contains('Hello, world!') ||
        !result.stdout.contains('2 arguments: [foo, bar]')) {
      print(
          'Error: `bazel run examples/hello_bin:$target` did not print correctly:');
      print(indent(result.stdout));
      exit(1);
    }
  }
}

void testBuildDartWebBinary() {
  print('Building some dart_web_binaries...');
  var result = bazel(['build', 'examples/web_app:all']);
  if (!result.stderr.contains('Found 4 targets')) {
    print(
        'Error: `bazel build examples/hello_bin:all` did not find 4 targets:');
    print(indent(result.stderr));
    exit(1);
  }
}

void testGenruleTest() {
  print('Testing the genrule test...');
  var result = bazel(['test', 'examples/hello_genrule:message_test']);
  if (!new RegExp(r'//examples/hello_genrule:message_test\s+PASSED')
          .hasMatch(result.stdout) ||
      !new RegExp(r'Executed 1 out of 1 test: 1 test passes.')
          .hasMatch(result.stdout)) {
    print(
        'Error: `bazel test examples/hello_genrule:message_test` did not pass!');
    print(indent(result.stdout));
    exit(1);
  }
}

ProcessResult bazel(List<String> args, {int expectedExitCode: 0}) {
  var command = args.removeAt(0);
  var result =
      Process.runSync('bazel', [command, '--noshow_progress']..addAll(args));
  if (result.exitCode != expectedExitCode) {
    print('Error: Could not call `bazel $command ${args.join(' ')}`. '
        'RC ${result.exitCode}');
    exit(1);
  }
  return result;
}

String indent(s) => s.splitMapJoin('\n', onNonMatch: (s) => '    $s');

import 'dart:io';

/// Generates a file named {0} which has a function that emits text in file {1}.
void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Expected 2 arguemnts, got ${args.length}');
    exit(1);
  }
  new File(args[1]).writeAsStringSync(
    "String getGeneratedMessage() => '${new File(args[0]).readAsStringSync()}';"
  );
}

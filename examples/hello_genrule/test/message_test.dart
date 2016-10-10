import 'dart:io';

import 'message.dart' as $gen;

const _expected = 'There is a snake in my boot!';

void main() {
  var message = $gen.getGeneratedMessage();
  if (message != _expected) {
    stderr.writeln('Expected $_expected, got $message');
    exit(1);
  }
}

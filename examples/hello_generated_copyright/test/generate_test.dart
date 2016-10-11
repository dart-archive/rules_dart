library generate_test;

import 'dart:io';
import 'dart:mirrors';

void main() {
  var thisScript = currentMirrorSystem().findLibrary(#generate_test).uri.path;
  var parentDir = (thisScript.split('/')..removeLast()..removeLast()).join('/');
  var libDir = '$parentDir/lib';
  var entries = new Directory(libDir).listSync();
  if (entries.length == 0) {
    print('Error: No generated files');
    exit(1);
  }
  if (entries.length > 1) {
    print('Error: Too many generated files: $entries');
    exit(1);
  }
  var generatedFile = entries.single.path;
  var fileName = generatedFile.split('/').last;
  if (fileName != 'hello.g.dart') {
    print('Error: Wrong generated file: $fileName');
    exit(1);
  }
  var contents = new File(generatedFile).readAsStringSync();
  if (!contents.contains('Copyright ')) {
    print('Error: Generated file does not contain a copyright notice:');
    print(contents.splitMapJoin('\n', onNonMatch: (m) => '    $m'));
    exit(1);
  }
}

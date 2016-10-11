import 'dart:io';

void main(List<String> args) {
  String inExtension;
  String outExtension;
  String outDirectory;
  String srcsFile;

  // Stupid simple arg parsing.
  for (var arg in args.takeWhile((arg) => arg != '--')) {
    if (arg.startsWith('--in-extension=')) {
      inExtension = arg.split('=')[1];
    } else if (arg.startsWith('--out-extension=')) {
      outExtension = arg.split('=')[1];
    } else if (arg.startsWith('--out=')) {
      outDirectory = arg.split('=')[1];
    } else if (arg.startsWith('--srcs-file=')) {
      srcsFile = arg.split('=')[1];
    }
  }

  print('Parsed  --in-extension $inExtension');
  print('Parsed --out-extension $outExtension');
  print('Parsed           --out $outDirectory');
  print('Parsed     --srcs-file $srcsFile');

  String holder;
  for (var arg in args.skipWhile((arg) => arg != '--')) {
    if (arg.startsWith('--holder=')) {
      holder = arg.split('=')[1];
    }
  }

  print('Parsed        --holder $holder');

  var srcsList = new File(srcsFile).readAsLinesSync();
  var year = new DateTime.now().year;
  for (var srcFile in srcsList) {
    if (!srcFile.endsWith(inExtension)) {
      continue;
    }
    var outFile = '$outDirectory/$srcFile'
        .replaceFirst(new RegExp('$inExtension\$'), outExtension);
    new File(outFile).writeAsString('''
// Copyright $year $holder. All rights reserved.
${new File(srcFile).readAsStringSync()}''');
  }
}

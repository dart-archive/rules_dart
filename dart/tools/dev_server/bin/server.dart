import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main() {
  var handler = createStaticHandler(Platform.environment['RUNFILES'],
      serveFilesOutsidePath: true,
      defaultDocument: 'index.html',
      listDirectories: true);

  io.serve(handler, 'localhost', 8080);
  print('Server running on localhost:8080');
}

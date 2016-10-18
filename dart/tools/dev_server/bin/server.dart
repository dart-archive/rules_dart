import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main() {
  var handler = createStaticHandler(
      path.join(Platform.environment['RUNFILES'],
          Platform.environment['BAZEL_WORKSPACE_NAME']),
      serveFilesOutsidePath: true,
      defaultDocument: 'index.html',
      listDirectories: true);

  io.serve(handler, 'localhost', 8080);
  print('Server running on localhost:8080');
}

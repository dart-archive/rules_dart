import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main() {
  var handler =
      createStaticHandler(Directory.current.path, /*defaultDocument: 'index.html',*/ listDirectories:true);

  io.serve(handler, 'localhost', 8080);
}

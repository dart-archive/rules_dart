import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';

Future main(List<String> args) async {
  var parsedArgs = _parser.parse(args);
  _buildTarget = parsedArgs[_buildTargetOption];
  var watchPaths = parsedArgs[_watchOption];

  // --build-target and --watch have to be used together
  if (_buildTarget.isEmpty != watchPaths.isEmpty) {
    print('--build-target and --watch arguments have to be used together');
    exit(1);
  }

  var pipeline = new Pipeline()
      .addMiddleware(createMiddleware(requestHandler: _blockForOngoingBuilds))
      .addHandler(createStaticHandler(
          path.join(Platform.environment['RUNFILES'],
              Platform.environment['BAZEL_WORKSPACE_NAME']),
          serveFilesOutsidePath: true,
          defaultDocument: 'index.html',
          listDirectories: true));

  io.serve(pipeline, 'localhost', 8080);
  print('Server running on localhost:8080');

  for (var path in watchPaths) {
    final watcher = await FileSystemEntity.isDirectory(path)
        ? new DirectoryWatcher(path)
        : new FileWatcher(path);
    watcher.events.listen((WatchEvent event) {
      // If people watch '.', make sure we don't run builds for changes in the
      // bazel generated folders.
      // TODO: make this more robust.
      if (event.path.startsWith('bazel-')) return;
      scheduleBuild();
    });
  }
}

// A request handler which blocks during ongoing builds, and returns the last
// error if the build is currently broken (and otherwise null).
Future<Response> _blockForOngoingBuilds(Request request) async {
  var error = await _currentBuildCompleter.future;
  if (error != null) {
    return new Response.internalServerError(
        body: 'Latest build failed with:\n\n$error');
  }
}

// Assigned at the top of main.
String _buildTarget;

// Keep track of current build status. If a String is returned then it contains
// an error.
var _currentBuildCompleter = new Completer<String>()..complete(null);

void scheduleBuild() {
  if (!_currentBuildCompleter.isCompleted) return;
  _currentBuildCompleter = new Completer<String>();
  print('Building $_buildTarget...');
  var watch = new Stopwatch()..start();
  new Future.delayed(new Duration(milliseconds: 250), () async {
    var result = await Process.run('bazel', [
      'build',
      _buildTarget,
      '--strategy=DartDevCompiler=worker',
      '--strategy=DartSummary=worker'
    ]);
    watch.stop();
    if (result.exitCode == 0) {
      print('Succeeded after ${watch.elapsedMilliseconds}ms');
      _currentBuildCompleter.complete(null);
    } else {
      print('\nBuild failed!!!\n\n${result.stderr}\n');
      _currentBuildCompleter.complete(result.stderr);
    }
  });
}

const _buildTargetOption = 'build-target';
const _watchOption = 'watch';

final _parser = new ArgParser()
  ..addOption(_buildTargetOption,
      help: 'A build target to watch for edits and rebuild', defaultsTo: '')
  ..addOption(_watchOption,
      allowMultiple: true,
      help: 'One or more files or directories to watch and trigger rebuilds');

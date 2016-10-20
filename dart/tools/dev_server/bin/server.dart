import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';

String get _workspacePath => p.join(Platform.environment['RUNFILES'],
    Platform.environment['BAZEL_WORKSPACE_NAME']);

Future main(List<String> args) async {
  var parsedArgs = _parser.parse(args);
  _buildTarget = parsedArgs[_buildTargetOption];
  var watchPaths = parsedArgs[_watchOption];
  var packageSpec = parsedArgs[_packageSpec];

  // --build-target and --watch have to be used together
  if (_buildTarget.isEmpty != watchPaths.isEmpty) {
    print('--build-target and --watch arguments have to be used together');
    exit(1);
  }

  if (packageSpec?.isEmpty == false) {
    var packageSpecLines = new File(p.join(_workspacePath, packageSpec))
        .readAsLinesSync()
        .where((l) => !l.startsWith(new RegExp('^\s*#')));
    for (var line in packageSpecLines) {
      var parts = line.split(':');
      assert(parts.length == 2);
      _packagePaths[parts[0]] = parts[1];
    }
  }

  var pipeline = new Pipeline()
      .addMiddleware(createMiddleware(requestHandler: _blockForOngoingBuilds))
      .addMiddleware(_base64EncodeSummariesHandler)
      .addMiddleware(_reroutePackagesPaths)
      .addHandler(createStaticHandler(_workspacePath,
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
      _scheduleBuild();
    });
  }
}

/// Map of package names to paths.
final _packagePaths = <String, String>{};

/// Changes any request containing a `packages` dir to route to the right place.
Handler _reroutePackagesPaths(Handler innerHandler) => (Request request) {
      var parts = request.requestedUri.pathSegments;
      var packagesIndex = parts.indexOf('packages');
      if (packagesIndex == -1) return innerHandler(request);

      if (parts.length < packagesIndex + 3) {
        return new Response.internalServerError(
            body: 'Invalid `packages` path, must contain at least 2 segments '
                'after `packages`');
      }

      var packagePath = _packagePaths[parts[packagesIndex + 1]];
      if (packagePath == null) {
        return new Response.internalServerError(
            body: 'Unrecognized `packages` path. Make sure the package appears '
                'in your dependencies.');
      }

      var filePath = p.url.joinAll([packagePath]
        ..addAll(parts.getRange(packagesIndex + 2, parts.length)));
      // TODO: Change this to use `request.change(path: filePath)`? That doesn't
      // seem to allow what we want though.
      var newRequest = new Request(
          request.method, request.requestedUri.replace(path: filePath),
          protocolVersion: request.protocolVersion,
          headers: request.headers,
          handlerPath: request.handlerPath,
          body: request.read(),
          encoding: request.encoding,
          context: request.context);
      return innerHandler(newRequest);
    };

/// A request handler which blocks during ongoing builds, and returns the last
/// error if the build is currently broken (and otherwise null).
Future<Response> _blockForOngoingBuilds(Request request) async {
  var error = await _currentBuildCompleter.future;
  if (error != null) {
    return new Response.internalServerError(
        body: 'Latest build failed with:\n\n$error');
  }
  return null;
}

// Handle summaries in a special way by base64 encoding them.
Handler _base64EncodeSummariesHandler(Handler innerHandler) =>
    (Request request) async {
      Response response = await innerHandler(request);

      // BASE64 encode strong mode summaries.
      var extension = p.extension(request.requestedUri.path);
      if ((extension == '.ds' || extension == '.sum') &&
          response?.statusCode == 200) {
        var bytes = await response.read().expand((i) => i).toList();
        return new Response.ok(BASE64.encode(bytes),
            headers: new Map.from(response.headers)..remove('content-length'),
            encoding: response.encoding,
            context: response.context);
      }
      return response;
    };

/// The build target to run (if any).
String _buildTarget;

/// Keep track of current build status. If a String is returned then it contains
/// an error.
var _currentBuildCompleter = new Completer<String>()..complete(null);

/// Schedules a build if one isn't already scheduled.
void _scheduleBuild() {
  if (!_currentBuildCompleter.isCompleted) return;
  _currentBuildCompleter = new Completer<String>();
  print('Building $_buildTarget...');
  new Future.delayed(new Duration(milliseconds: 100), () async {
    var watch = new Stopwatch()..start();
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
const _packageSpec = 'package-spec';
const _watchOption = 'watch';

final _parser = new ArgParser()
  ..addOption(_buildTargetOption,
      help: 'A build target to watch for edits and rebuild', defaultsTo: '')
  ..addOption(_watchOption,
      allowMultiple: true,
      help: 'One or more files or directories to watch and trigger rebuilds')
  ..addOption(_packageSpec,
      help: 'A .packages spec which is used to route packages paths');

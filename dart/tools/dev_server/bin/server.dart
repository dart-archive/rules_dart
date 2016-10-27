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
  for (var substitution in parsedArgs[_uriSubstitution]) {
    var parts = substitution.split(':');
    assert(parts.length == 2);
    _uriSubstitutions[parts[0]] = parts[1];
  }

  // --build-target and --watch have to be used together
  if (_buildTarget.isEmpty != watchPaths.isEmpty) {
    print('--build-target and --watch arguments have to be used together');
    // command line usage error
    exitCode = 64;
    // return instead of calling exit(...) – allows debugging, code coverage
    return;
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
      .addMiddleware(_applyUriSubstitutions)
      .addMiddleware(_reroutePackagesPaths)
      .addHandler(createStaticHandler(_workspacePath,
          serveFilesOutsidePath: true, listDirectories: true));

  io.serve(pipeline, 'localhost', 8080);
  print('Server running on localhost:8080');

  for (var path in watchPaths) {
    Watcher watcher;
    if (await FileSystemEntity.isDirectory(path)) {
      watcher = new DirectoryWatcher(path);
    } else if (await FileSystemEntity.isFile(path)) {
      watcher = new FileWatcher(path);
    } else {
      print('Ignoring non-existent watch path `$path`');
      continue;
    }

    watcher.events.listen((WatchEvent event) {
      // If people watch '.', make sure we don't run builds for changes in the
      // bazel generated folders.
      // TODO: make this more robust.
      if (event.path.startsWith('bazel-')) return;
      _scheduleBuild();
    });
  }
}

/// Map of uri substitutions to be applied in [_applyUriSubstitutions]
final _uriSubstitutions = <String, String>{};

/// [Middleware] that applies [_uriSubstitutions].
Handler _applyUriSubstitutions(Handler innerHandler) => (Request request) {
      var newPath = request.requestedUri.path;
      _uriSubstitutions.forEach((from, to) {
        newPath = newPath.replaceFirst(from, to);
      });
      if (newPath != request.requestedUri.path) {
        request = _changeRequestPath(
            request, request.requestedUri.replace(path: newPath));
      }
      return innerHandler(request);
    };

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
      var newRequest = _changeRequestPath(
          request, request.requestedUri.replace(path: filePath));
      return innerHandler(newRequest);
    };

/// Takes a [Request] and updates its uri to [newUri].
/// TODO: We should be using `original.change` but its overly restrictive.
Request _changeRequestPath(Request original, Uri newUri) =>
    new Request(original.method, newUri,
        protocolVersion: original.protocolVersion,
        headers: original.headers,
        handlerPath: original.handlerPath,
        body: original.read(),
        encoding: original.encoding,
        context: original.context);

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
const _uriSubstitution = 'uri-substitution';
const _watchOption = 'watch';

final _parser = new ArgParser()
  ..addOption(_buildTargetOption,
      help: 'A build target to watch for edits and rebuild', defaultsTo: '')
  ..addOption(_watchOption,
      allowMultiple: true,
      help: 'One or more files or directories to watch and trigger rebuilds')
  ..addOption(_packageSpec,
      help: 'A .packages spec which is used to route packages paths')
  ..addOption(_uriSubstitution,
      allowMultiple: true,
      help: 'Reroutes paths from one path to another using `.replaceFirst` on '
          'all incoming requests. The format is `--uri-substitution=from:to`.');

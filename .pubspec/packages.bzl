PUB_PACKAGE_NAME = "rules_dart_tools"

def bazelify():
    native.new_local_repository(
        name = "async",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/async-1.11.2",
        build_file = ".bazelify/async.BUILD",
    )
    
    native.new_local_repository(
        name = "charcode",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/charcode-1.1.0",
        build_file = ".bazelify/charcode.BUILD",
    )
    
    native.new_local_repository(
        name = "collection",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/collection-1.9.1",
        build_file = ".bazelify/collection.BUILD",
    )
    
    native.new_local_repository(
        name = "convert",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/convert-2.0.1",
        build_file = ".bazelify/convert.BUILD",
    )
    
    native.new_local_repository(
        name = "http_parser",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/http_parser-3.0.3",
        build_file = ".bazelify/http_parser.BUILD",
    )
    
    native.new_local_repository(
        name = "mime",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/mime-0.9.3",
        build_file = ".bazelify/mime.BUILD",
    )
    
    native.new_local_repository(
        name = "path",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/path-1.4.0",
        build_file = ".bazelify/path.BUILD",
    )
    
    native.new_local_repository(
        name = "shelf",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/shelf-0.6.5+3",
        build_file = ".bazelify/shelf.BUILD",
    )
    
    native.new_local_repository(
        name = "shelf_static",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/shelf_static-0.2.4",
        build_file = ".bazelify/shelf_static.BUILD",
    )
    
    native.new_local_repository(
        name = "source_span",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/source_span-1.2.3",
        build_file = ".bazelify/source_span.BUILD",
    )
    
    native.new_local_repository(
        name = "stack_trace",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/stack_trace-1.6.8",
        build_file = ".bazelify/stack_trace.BUILD",
    )
    
    native.new_local_repository(
        name = "stream_channel",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/stream_channel-1.5.0",
        build_file = ".bazelify/stream_channel.BUILD",
    )
    
    native.new_local_repository(
        name = "string_scanner",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/string_scanner-1.0.0",
        build_file = ".bazelify/string_scanner.BUILD",
    )
    
    native.new_local_repository(
        name = "typed_data",
        path = "/Users/srawlins/.pub-cache/hosted/pub.dartlang.org/typed_data-1.1.3",
        build_file = ".bazelify/typed_data.BUILD",
    )
    

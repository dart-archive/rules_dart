"""Utilities to build aspects that collect files from targets."""

def _matches_extension(f, extensions):
  for extension in extensions:
    if f.path.endswith(extension):
      return True
  return False

def _collect_files_for_attribute(attribute):
  return [f for value in attribute for f in value.files]

def _filter_by_extensions(files, extensions):
  return [f for f in files if _matches_extension(f, extensions)]

def _codegen_aspect_impl(target, ctx):
  """Collects files from `srcs` that match provided extensions."""
  srcs = {}
  aspect_name = ctx.attr._name
  if hasattr(target, "dart_codegen"):
    srcs.update(target.dart_codegen.srcs)

  matching_files = set()
  extensions = ctx.attr._extensions
  matching_files += _filter_by_extensions(target.dart.srcs, extensions)
  if hasattr(ctx.rule.attr, "data"):
    matching_files += _filter_by_extensions(
        _collect_files_for_attribute(ctx.rule.attr.data), extensions)

  srcs[aspect_name] = matching_files
  return struct(dart_codegen = struct(srcs = srcs))

def dart_codegen_aspect(aspect_name, extensions):
  """Create an Aspect to gather files from `srcs` and `data` by extension."""
  return aspect(
      implementation = _codegen_aspect_impl,
      attr_aspects = ["deps"],
      attrs = {
          "_extensions": attr.string_list(default = extensions),
          "_name": attr.string(default = aspect_name),
      },
  )

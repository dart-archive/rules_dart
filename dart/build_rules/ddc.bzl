load(
    ":internal.bzl",
    "dart_filetypes",
    "filter_files",
    "has_dart_sources",
    "make_package_uri",
    "api_summary_extension",
)

def ddc_action(ctx, dart_ctx, ddc_output, source_map_output):
  """ddc compile action."""
  flags = []

  # TODO: workaround for ng2/templates until they are better typed
  flags.append("--unsafe-angular2-whitelist")

  # Specify the extension used for API summaries in Google3
  flags.append("--summary-extension=%s" % api_summary_extension)

  inputs = []
  strict_transitive_srcs = set([])

  # Specify all input summaries on the command line args
  for dep in dart_ctx.transitive_deps.values():
    strict_transitive_srcs += dep.dart.srcs
    if has_dart_sources(dep.dart.srcs):
      if dep.ddc.output and dep.dart.strong_summary:
        inputs.append(dep.dart.strong_summary)
        flags += ["-s", dep.dart.strong_summary.path]
      else:
        # TODO: produce an error here instead.
        print("missing summary for %s" % dep.label)

  # Specify the output location
  outputs = [ddc_output]
  if source_map_output:
    outputs.append(source_map_output)
  flags += ["-o", ddc_output.path]

  # TODO: Use a standard JS module system instead of our homegrown one.
  # We'll need to also use the corresponding dart-sdk when we change this.
  flags += ["--modules", "legacy"]

  flags.append("--inline-source-map")
  flags.append("--single-out-file")

  input_paths = []

  for f in filter_files(dart_filetypes, dart_ctx.srcs):
    if hasattr(ctx.attr, "web_exclude_srcs") and f in ctx.files.web_exclude_srcs:
      # Files that we ignore for DDC compilation.
      continue
    if f in strict_transitive_srcs:
      # Skip files that are already a part of a dependency.
      # Note: we don't emit a warning because it's unclear at this
      # point what we would like users to do to get rid of the issue.
      continue

    inputs.append(f)
    normalized_path = make_package_uri(dart_ctx, f.short_path)
    flags += ["--url-mapping", "%s,%s" % (normalized_path, f.path)]
    flags += ["--bazel-mapping", "%s,/%s" % (f.path, f.short_path)]
    input_paths.append(normalized_path)

  # We normalized file:/// paths, so '/' corresponds to the top of google3.
  flags += ["--build-root", "/"]
  flags += ["--module-root", ddc_output.root.path]
  flags += ["--no-summarize"]

  # Specify the input files after all flags
  flags += input_paths

  # Sends all the flags to an output file, for worker support
  flags_file = ctx.new_file(ctx.label.name + "_ddc_args")
  ctx.file_action(output = flags_file, content = "\n".join(flags))
  inputs += [flags_file]
  flags = ["@%s" % flags_file.path]

  ctx.action(
      inputs=inputs,
      executable=ctx.executable._dev_compiler,
      arguments=flags,
      outputs=outputs,
      progress_message="Compiling %s with ddc" % ctx.label,
      mnemonic="DartDevCompiler",
      execution_requirements={"supports-workers": "1"},
  )

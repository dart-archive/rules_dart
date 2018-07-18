load(
    ":common.bzl",
    "dart_filetypes",
    "filter_files",
    "has_dart_sources",
    "make_dart_context",
    "make_package_uri",
    "api_summary_extension",
)

def ddc_action(ctx, dart_ctx, ddc_output, source_map_output):
  """ddc compile action."""
  flags = []

  if ctx.attr.force_ddc_compile:
    print("Force compile %s?" % ctx.label.name
          + " sounds a bit too strong for a library that is"
          + " not strong clean, doesn't it?")
    flags.append("--unsafe-force-compile")

  # Specify the extension used for API summaries in Google3
  flags.append("--summary-extension=%s" % api_summary_extension)

  inputs = []
  strict_transitive_srcs = depset([])

  # Specify all input summaries on the command line args
  for dep in dart_ctx.transitive_deps.targets.values():
    if not dep.ddc.enabled:
      continue

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

    flags += ["--bazel-mapping", "%s,/%s" % (f.path, f.path)]
    input_paths.append(normalized_path)
  # We normalized file:/// paths, so '/' corresponds to the top of google3.
  flags += ["--library-root", "/"]
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

def dart_ddc_bundle_outputs(output_dir, output_html):
  html = "%{name}.html"

  if output_html:
    html = output_html
  elif output_dir:
    html = "%s/%s" % (output_dir, html)

  prefix = _output_dir(output_dir, output_html) + "%{name}"

  return {
      "html": html,
      "app": "%s.js" % prefix,
      "package_spec": "%{name}.packages",
  }

# Computes the output dir based on output_dir and output_html options.
def _output_dir(output_dir, output_html):
  if output_html and output_dir:
    fail("Cannot use both output_dir and output_html")

  if output_html and "/" in output_html:
    output_dir = "/".join(output_html.split("/")[0:-1])

  if output_dir and not output_dir.endswith("/"):
    output_dir = "%s/" % output_dir

  if not output_dir:
    output_dir = ""

  return output_dir

def dart_ddc_bundle_impl(ctx):
  dart_ctx = make_dart_context(ctx, deps = [ctx.attr.entry_module])

  inputs = []
  sourcemaps = []
  # Initialize map of dart srcs to packages, if checking duplicate srcs
  if ctx.attr.check_duplicate_srcs:
    dart_srcs_to_pkgs = {}

  for dep in dart_ctx.transitive_deps.targets.values():
    if dep.ddc.enabled and has_dart_sources(dep.dart.srcs):
      # Collect dict of dart srcs to packages, if checking duplicate srcs
      # Note that we skip angular2 which is an exception to this rule for now.
      if (ctx.attr.check_duplicate_srcs and
          dep.label.package.endswith("angular2")):
        all_dart_srcs = [f for f in dep.dart.srcs if f.path.endswith(".dart")]
        for src in all_dart_srcs:
          label_name = "%s:%s" % (dep.label.package, dep.label.name)
          if src.short_path in dart_srcs_to_pkgs:
            dart_srcs_to_pkgs[src.short_path] += [label_name]
          else:
            dart_srcs_to_pkgs[src.short_path] = [label_name]

      if dep.ddc.output:
        inputs.append(dep.ddc.output)
        if dep.ddc.sourcemap:
          sourcemaps.append(dep.ddc.sourcemap)
      else:
        # TODO: eventually we should fail here.
        print("missing ddc code for %s" % dep.label)

  # Actually check for duplicate dart srcs, if enabled
  if ctx.attr.check_duplicate_srcs:
    for src in dart_srcs_to_pkgs:
      if len(dart_srcs_to_pkgs[src]) > 1:
        print("%s found in multiple libraries %s" %
              (src, dart_srcs_to_pkgs[src]))

  ctx.action(
      inputs = inputs,
      executable = ctx.file._ddc_concat,
      arguments = [ctx.outputs.app.path] + [f.path for f in inputs],
      outputs = [ctx.outputs.app],
      progress_message = "Concatenating ddc output files for %s" % ctx,
      mnemonic = "DartDevCompilerConcat")

  module = ""
  if ctx.attr.entry_module.label.package:
    module = module + ctx.attr.entry_module.label.package + "/"
  module = module + ctx.attr.entry_module.label.name
  name = ctx.label.name
  package = ctx.label.package
  library = ""
  if package:
    library = library + package + "/"
  library = (library + ctx.attr.entry_library).replace("/", "__")
  ddc_runtime_prefix = "%s." % ctx.label.name
  html_gen_flags = [
      "--entry_module", module,
      "--entry_library", library,
      "--ddc_runtime_prefix", ddc_runtime_prefix,
      "--script", "%s.js" % name,
      "--out", ctx.outputs.html.path,
  ]

  html_gen_inputs = []
  input_html = ctx.attr.input_html
  if input_html:
    input_file = ctx.files.input_html[0]
    html_gen_inputs.append(input_file)
    html_gen_flags += ["--input_html", input_file.path]

  if ctx.attr.include_test:
    html_gen_flags.append("--include_test")

  ctx.action(
      inputs = html_gen_inputs,
      outputs = [ctx.outputs.html],
      executable = ctx.file._ddc_html_generator,
      arguments = html_gen_flags)

  for f in ctx.files._ddc_support:
    if f.path.endswith("dart_library.js"):
      ddc_dart_library = f
    if f.path.endswith("dart_sdk.js"):
      ddc_dart_sdk = f
  if not ddc_dart_library:
    fail("Unable to find dart_library.js in the ddc support files. " +
         "Please file a bug on Chrome -> Dart -> Devtools")
  if not ddc_dart_sdk:
    fail("Unable to find dart_sdk.js in the ddc support files. " +
         "Please file a bug on Chrome -> Dart -> Devtools")

  # TODO: Do we need to prefix with workspace root?
  ddc_runtime_output_prefix = "%s/%s/%s%s" % (
      ctx.workspace_name,
      ctx.label.package,
      _output_dir(ctx.attr.output_dir, ctx.attr.output_html),
      ddc_runtime_prefix)

  # Create a custom package spec which provides paths relative to
  # $RUNFILES/$BAZEL_WORKSPACE_NAME.
  _ddc_package_spec_action(ctx, dart_ctx, ctx.outputs.package_spec)

  runfiles = depset(ctx.files._ddc_support)
  runfiles += [ctx.outputs.package_spec]
  for dep in dart_ctx.transitive_deps.targets.values():
    runfiles += dep.dart.srcs
    runfiles += dep.dart.data
    runfiles += [dep.dart.strong_summary]

  # Find the strong_summary file for the sdk
  for f in ctx.files._sdk_summaries:
    if f.path.endswith("strong.sum"):
      sdk_strong_summary = f
      break
  if not sdk_strong_summary:
    fail("unable to find sdk strong summary")

  for f in ctx.files._js_pkg:
    if f.path.endswith("js.api.ds"):
      pkg_js_summary = f;
      break
  if not pkg_js_summary:
    fail("unable to find js package summary")

  return struct(
      dart=dart_ctx,
      runfiles=ctx.runfiles(
          files=list(runfiles),
          root_symlinks={
              "%sdart_library.js" % ddc_runtime_output_prefix: ddc_dart_library,
              "%sdart_sdk.js" % ddc_runtime_output_prefix: ddc_dart_sdk,
              "%s/third_party/dart_lang/trunk/sdk/lib/_internal/strong.sum" % ctx.workspace_name: sdk_strong_summary,
              "%s/third_party/dart/js/js.api.ds" % ctx.workspace_name: pkg_js_summary,
          }
      ),
  )

def _ddc_package_spec_action(ctx, dart_ctx, output):
  """Creates an action that generates a Dart package spec for the server to use.
  Paths are all relative to $RUNFILES/$WORKSPACE_DIR.

  Arguments:
    ctx: The rule context.
    dart_ctx: The Dart context.
    output: The output package_spec file.
  """

  # Generate the content.
  content = "# Generated by Bazel\n"
  seen_packages = depset([])
  for dc in dart_ctx.transitive_deps.targets.values():
    if not dc.dart.package:
      continue

    # Don't duplicate packages
    if dc.dart.package in seen_packages:
      continue
    seen_packages += [dc.dart.package]

    lib_root = "/"
    if dc.dart.label.workspace_root:
      lib_root += dc.dart.label.workspace_root + "/"
    if dc.dart.label.package:
      lib_root += dc.dart.label.package + "/"
    lib_root += "lib/"

    content += "%s:%s\n" % (dc.dart.package, lib_root)

  # Emit the package spec.
  ctx.file_action(
      output=output,
      content=content,
  )

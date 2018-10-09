load(
    ":common.bzl",
    "compute_layout",
    "dart_filetypes",
    "filter_files",
    "has_dart_sources",
    "layout_action",
    "make_package_uri",
    "package_spec_action",
)

def analyze_action(
        ctx,
        dart_ctx,
        summary = None,
        use_summaries = True,
        analysis = None,
        fail_on_error = True,
        x_perf_report = None):
    """Runs the analyzer.

    Arguments:
      ctx: The rule context.
      dart_ctx: The Dart context.
      summary: The output semantic summary file, or `None` if no semantic
          summary is desired (analyzer tests for instance).  Defaults to `None`.
      use_summaries: `True` if summaries from dart_ctx.transitive_deps should be
          used to speed up analysis.  Defaults to `True`.
      analysis: Output file to which analysis should be sent, or `None` if no
          analysis should be done.
      fail_on_error: `True` if an analysis error should fail the build.
          Defaults to `True`.
      x_perf_report: Output file to which a performance report should be
          written, or `None` if no performance report should be output.
          Defaults to `None`.

    Temporary files and directories used by this action are:
    - $LABEL.analyze: directory in which analysis occurs
    - $LABEL_layout.sh: script to layout the files in $LABEL.analyze
    - $LABEL_analyze.sh: script to run the analyzer

    """

    # Figure out the mode in which we need analyzer to run.  We need to
    # decide:
    # - whether to run in build mode: we prefer to, but it doesn't
    #   support a configurable package URI resolver so it can't analyze
    #   the full transitive closure of packages all at once.
    use_build_mode = use_summaries

    # - whether we can tell the analyzer to skip error/warning/hint
    #   generation.  This only works in package mode.
    skip_analysis = use_build_mode and not analysis and not fail_on_error

    # - whether we need to ignore the exit code of the analyzer.  This
    #   is necessary if we aren't skipping analysis, but we don't want
    #   to fail on error.
    ignore_exit_code = not skip_analysis and not fail_on_error

    # - whether to run using a wrapper script: we need to if we want to
    #   capture analysis from standard output, or we need to ignore the
    #   analyzer's exit code.
    script_needed = (not use_build_mode and
                     (analysis != None or ignore_exit_code))
    if (summary != None) and not use_build_mode:
        fail("Generating summaries requires build mode")

    strict_transitive_srcs = depset([])
    for dep in dart_ctx.transitive_deps.targets.values():
        strict_transitive_srcs += dep.dart.srcs

    # Figure out which files should be analyzed.
    if use_summaries:
        analysis_srcs = [
            src
            for src in dart_ctx.srcs
            if src not in strict_transitive_srcs
        ]
    else:
        analysis_srcs = dart_ctx.transitive_srcs.files
    if use_build_mode:
        # We can analyze the source files in place.
        analyze_dir_files = compute_layout(analysis_srcs)
    else:
        # Build a flattened directory containing the files to be analyzed.
        analyze_dir = ctx.label.name + ".analyze/"
        analyze_dir_files = layout_action(ctx, analysis_srcs, analyze_dir)

    # Build a package spec if needed.
    if not use_build_mode:
        package_spec_path = ctx.label.package + "/" + ctx.label.name + ".packages"
        package_spec = ctx.actions.declare_file(analyze_dir + package_spec_path)
        package_spec_action(ctx, dart_ctx, package_spec)

    # Emit the script to run analyzer, if necessary.
    if script_needed:
        content = "#!/bin/bash\n"
        content += ctx.executable._analyzer.path
        content += " $@"
        if analysis and not use_build_mode:
            content += " 2> " + analysis.path
        content += "\n"
        if ignore_exit_code and not use_build_mode:
            content += "exit 0\n"
        executable = ctx.actions.declare_file(ctx.label.name + "_analyze.sh")
        ctx.actions.write(
            output = executable,
            content = content,
            executable = True,
        )
    else:
        executable = ctx.executable._analyzer

    # Find dependent contexts, filtering out those with no sources.
    dependent_ctxs = [
        dep.dart
        for dep in dart_ctx.transitive_deps.targets.values()
        if has_dart_sources(dep.dart.srcs)
    ]

    # Compute action inputs
    inputs = []
    inputs += analyze_dir_files.values()
    if use_summaries:
        for dc in dependent_ctxs:
            s = dc.strong_summary
            if s:
                inputs += [s]
    else:
        inputs += [package_spec]

    # Compute input manifests
    if script_needed:
        additional_inputs, _, input_manifests = ctx.resolve_command(
            tools = [ctx.attr._analyzer],
        )
        inputs += additional_inputs
    else:
        input_manifests = None

    # Compute action outputs
    outputs = []
    if summary:
        outputs += [summary]
    if analysis:
        outputs += [analysis]
    if x_perf_report:
        outputs += [x_perf_report]

    # Compute analyzer args
    analyzer_args = []
    analyzer_args += ["--format=machine"]
    if use_build_mode:
        analyzer_args += ["--build-mode"]
        if use_summaries and dependent_ctxs:
            # TODO: this can be deleted and the code to compute summaries
            # below can be simplified once summaries are on by default. This is
            # mainly used to report errors when a rule with summaries depends on
            # another rule without them.
            for dc in dependent_ctxs:
                if not dc.strong_summary:
                    print("%s is missing summaries" % dc.label)
            analyzer_args += ["--build-summary-input=%s" % ",".join(
                [
                    s.path
                    for s in [dc.strong_summary for dc in dependent_ctxs]
                    if s
                ],
            )]
        if summary:
            analyzer_args += ["--build-summary-output-semantic=%s" % summary.path]
        if skip_analysis:
            analyzer_args += ["--build-summary-only"]
        if analysis:
            analyzer_args += ["--build-analysis-output=%s" % analysis.path]
        if ignore_exit_code:
            analyzer_args += ["--build-suppress-exit-code"]
    if not use_summaries:
        analyzer_args += ["--packages=%s" % package_spec.path]
    if x_perf_report:
        analyzer_args += ["--x-perf-report=%s" % x_perf_report.path]
    short_paths_to_analyze = [
        f.short_path
        for f in filter_files(dart_filetypes, dart_ctx.srcs)
        if f not in strict_transitive_srcs
    ]

    if use_build_mode:
        analyzer_args += [
            "%s|%s" % (
                make_package_uri(dart_ctx, p),
                analyze_dir_files[p].path,
            )
            for p in short_paths_to_analyze
        ]
    else:
        analyzer_args += [
            analyze_dir_files[p].path
            for p in short_paths_to_analyze
        ]

    # Make an action to run the analyzer.
    execution_requirements = {}
    if summary:
        verb = "Summarizing"
        mnemonic = "DartSummary"
        if use_build_mode:
            # All arguments go into a file for worker mode support.
            args_file = ctx.actions.declare_file(
                ctx.label.name + "_worker_args",
            )
            ctx.actions.write(
                output = args_file,
                content = "\n".join(analyzer_args),
            )
            inputs += [args_file]

            # The new args should just be "--build-mode" and "@args_file_path"
            analyzer_args = ["--build-mode", "@%s" % args_file.path]

            # This is needed to signal Blaze that the action actually supports
            # running as a worker.
            execution_requirements["supports-workers"] = "1"
    else:
        verb = "Analyzing"
        mnemonic = "DartAnalysis"

    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        executable = executable,
        arguments = analyzer_args,
        progress_message = "%s Dart library %s" % (verb, ctx),
        mnemonic = mnemonic,
        execution_requirements = execution_requirements,
        input_manifests = input_manifests,
    )

def summary_action(ctx, dart_ctx):
    """Run the analyzer to create summaries."""

    # If a strong_summary is declared, we assume summaries are enabled.
    if dart_ctx.strong_summary:
        if not dart_ctx.dart_srcs:
            ctx.actions.write(
                output = dart_ctx.strong_summary,
                content = (
                    "// empty summary, package %s has no dart sources\n" %
                    ctx.label.name
                ),
            )
        else:
            analyze_action(
                ctx,
                dart_ctx,
                summary = dart_ctx.strong_summary,
                fail_on_error = False,
            )

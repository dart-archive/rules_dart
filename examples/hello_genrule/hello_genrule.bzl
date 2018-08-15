def _hello_gen_impl(ctx):
    output_file_path = ctx.outputs.output_file.path
    ctx.action(
        inputs = [ctx.file.input_file],
        outputs = [ctx.outputs.output_file],
        arguments = [
            ctx.file.input_file.path,
            output_file_path,
        ],
        executable = ctx.executable._generator,
        progress_message = "Generating Dart file %s" % output_file_path,
        mnemonic = "HelloGenerator",
    )

hello_gen = rule(
    implementation = _hello_gen_impl,
    attrs = {
        "input_file": attr.label(
            allow_files = True,
            mandatory = True,
            single_file = True,
        ),
        "output_file": attr.string(mandatory = True),
        "_generator": attr.label(
            allow_files = True,
            cfg = "host",
            single_file = True,
            default = Label("//examples/hello_genrule:generate"),
            executable = True,
        ),
    },
    outputs = {
        "output_file": "%{output_file}",
    },
)

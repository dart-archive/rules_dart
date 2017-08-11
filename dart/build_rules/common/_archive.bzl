"""Custom internal impl of create_archive."""

def create_archive(ctx, srcs, label):
  """Creates an archive for the supplied srcs.

  Args:
    ctx: The target context.
    srcs: the srcs for the current target
    label: the label for the current target
  Returns:
    - A tar file which contains the supplied srcs.

  """
  commands = []
  for src in srcs:
    commands += ["mkdir -p $(dirname $ARCHIVE_DIR/%s)" % src.short_path]
    commands += ["cp -L %s $ARCHIVE_DIR/%s" % (src.path, src.short_path)]
  tmp_file = ctx.new_file(label.name + ".archive_inputs")
  ctx.file_action(output=tmp_file, content="\n".join(commands))
  tar_file = ctx.new_file(label.name + ".dart_archive.tar")
  ctx.action(
      inputs=srcs +[tmp_file],
      outputs=[tar_file],
      mnemonic="DartArchive",
      command="\n".join([
          "export WORKSPACE=${PWD}",
          "export ARCHIVE_DIR=$(mktemp -d)",
          "bash %s" % tmp_file.path,
          "cd $ARCHIVE_DIR",
          "tar -chf temp_tar.tar *",
          "cd $WORKSPACE",
          "cp $ARCHIVE_DIR/temp_tar.tar %s" % tar_file.path,
          "rm -rf \"$ARCHIVE_DIR\""]),
      progress_message="Creating Dart archive")
  return tar_file

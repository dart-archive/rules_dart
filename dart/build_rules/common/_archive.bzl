"""Custom internal impl of create_archive."""

def create_archive(ctx, srcs, name):
  """Creates an archive for the supplied srcs.

  Args:
    ctx: The target context.
    srcs: the srcs for the current target
    name: the name for the current target
  Returns:
    - A tar file which contains the supplied srcs.

  """
  commands = []
  for src in srcs:
    commands += ["mkdir -p $(dirname $ARCHIVE_DIR/%s)" % src.short_path]
    commands += ["cp -L %s $ARCHIVE_DIR/%s" % (src.path, src.short_path)]
  # Use the following options to ensure the archive creation is deterministic
  tar_command = "tar --mtime=@0 --owner=0 --group=0 -chf temp_tar.tar *"
  # Check for Exoblaze
  if not hasattr(native, "js_library"):
    # The above options are not available on Exoblaze
    tar_command = "tar -chf temp_tar.tar *"
  tmp_file = ctx.new_file(name + ".archive_inputs")
  ctx.file_action(output=tmp_file, content="\n".join(commands))
  tar_file = ctx.new_file(name + ".dart_archive.tar")
  ctx.action(
      inputs=srcs +[tmp_file],
      outputs=[tar_file],
      mnemonic="DartArchive",
      command="\n".join([
          "export WORKSPACE=${PWD}",
          "export ARCHIVE_DIR=$(mktemp -d)",
          "bash %s" % tmp_file.path,
          "cd $ARCHIVE_DIR",
          # This helps ensure archive creation is deterministic
          "find . -type f | xargs chmod 644",
          tar_command,
          "cd $WORKSPACE",
          "cp $ARCHIVE_DIR/temp_tar.tar %s" % tar_file.path,
          "rm -rf \"$ARCHIVE_DIR\""]),
      progress_message="Creating Dart archive %s" % ctx.label)
  return tar_file


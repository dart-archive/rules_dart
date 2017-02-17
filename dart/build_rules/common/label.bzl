"""Common utilities for working with skylark labels."""

def label_to_dart_package_name(label):
  """Returns the Dart package name for the specified label.

  External packages resolve to their Pub package names.
  All other packages resolve to a unique identifier based on their repo path.

  Examples:
    //foo/bar/baz:     -> foo.bar.baz
    @package//:package -> package

  Args:
    label: the label whose package name is to be returned.

  Returns:
    The Dart package name associated with the label.
  """
  package_name = label.package
  if label.workspace_root.startswith("external/"):
    package_name = label.workspace_root[len("external/"):]
  if "." in package_name:
    fail("Dart package paths may not contain '.': " + label.package)
  return package_name.replace("/", ".")

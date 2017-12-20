"""Skylib module containing functions that operate on dictionaries."""

def _add(*dictionaries):
  """Returns a new `dict` that has all the entries of the given dictionaries.

  If the same key is present in more than one of the input dictionaries, the
  last of them in the argument list overrides any earlier ones.

  This function is designed to take zero or one arguments as well as multiple
  dictionaries, so that it follows arithmetic identities and callers can avoid
  special cases for their inputs: the sum of zero dictionaries is the empty
  dictionary, and the sum of a single dictionary is a copy of itself.

  Args:
    *dictionaries: Zero or more dictionaries to be added.

  Returns:
    A new `dict` that has all the entries of the given dictionaries.
  """
  result = {}
  for d in dictionaries:
    result.update(d)
  return result


dicts = struct(
    add=_add,
)

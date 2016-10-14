#!/bin/bash
# Concatenates several files together

output=$1
shift
cat "$@" > "${output}"

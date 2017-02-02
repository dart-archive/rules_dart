#!/bin/bash
set -e

EMIT_TAR=false

if [[ $1 == "--emit-tar" ]]; then
  EMIT_TAR=true
  TAR_OUTPUT=$2
  BIN_DIR=$3
  OUTPUT_JS_SHORT_PATH=$4
  DEPLOY_DIR=$5
  shift 5
fi

DART2JS=$1
shift 1

"$DART2JS" "$@"

if [[ $EMIT_TAR == true ]]; then
  OUTPUT_JS_SHORT_DIR=$(dirname "$OUTPUT_JS_SHORT_PATH")
  DEST_DIR="$BIN_DIR/$DEPLOY_DIR/$OUTPUT_JS_SHORT_DIR"
  mkdir -p "$DEST_DIR"
  cp "$BIN_DIR/$OUTPUT_JS_SHORT_PATH"* "$DEST_DIR"
  tar cfh "$TAR_OUTPUT" -C "$BIN_DIR/$DEPLOY_DIR" . > /dev/null
fi

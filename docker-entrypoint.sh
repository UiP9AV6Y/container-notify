#!/bin/sh
set -eu

if test $# -gt 0; then
  case "$1" in
    -*)
      # some option argument
      break
      ;;
    container-notify)
      # remove argument as we prepend it later anyway
      shift
      ;;
    *)
      # command, unrelated to the purpose of this image
      exec "$@"
      ;;
  esac
fi

exec container-notify "$@"
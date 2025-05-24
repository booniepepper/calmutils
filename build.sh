#!/bin/sh

this="$(basename "$0")"
root="$(dirname "$0")"
outbin="$root/out/bin"

utils="false true wc"

for step in "$@"
do
  case "$1" in
    help) echo "USAGE: $this [ARG]" ;;

    build)
      mkdir -p "$outbin"
      for util in $utils;do
        zig build-exe "$root/src/$util.zig" -femit-bin="$outbin/$util"
      done
      ;;
    clean) rm -r "$outbin" ;;
    e2e) "$root/tests/run" ;;
    fmt) zig fmt "$root/src" ;;
    fuzz) for util in $utils; do zig test -ffuzz "$root/src/$util.zig"; done ;;
    test) for util in $utils; do zig test "$root/src/$util.zig"; done ;;
  esac
  shift
done

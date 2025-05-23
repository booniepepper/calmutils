#!/bin/sh

this="$(basename "$0")"
root="$(dirname "$0")"
outbin="$root/out/bin"

# TODO: handle more than one util
util=wc

for step in "$@"
do
  case "$1" in
    help) echo "USAGE: $this [ARG]" ;;

    build) mkdir -p "$outbin"; zig build-exe "$root/src/$util.zig" -femit-bin="$outbin/$util" ;;
    clean) rm -r "$outbin" ;;
    e2e) "$root/tests/run" ;;
    fmt) zig fmt "$root/src" ;;
    fuzz) zig test -ffuzz "$root/src/$util.zig" ;;
    test) zig test "$root/src/$util.zig" ;;
  esac
  shift
done

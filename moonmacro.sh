#!/bin/bash
set -e

# MoonMacro Preprocessor - processes .mbt.macro files to .mbt
# Usage: ./moonmacro.sh [file_or_dir ...]
#        ./moonmacro.sh install [dir]

BINDIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$BINDIR/_build/native/debug/build/mmprocess/mmprocess.exe"

build_binary() {
  echo "Building mmprocess binary..." >&2
  (cd "$BINDIR" && moon build --target native 2>&1)
  echo "Done building." >&2
}

find_binary() {
  if [ -f "$BINARY" ]; then
    echo "$BINARY"
  else
    local which_bin
    which_bin=$(command -v mmprocess 2>/dev/null) && echo "$which_bin" || echo ""
  fi
}

install_binary() {
  local target_dir="${1:-$HOME/.local/bin}"
  [ ! -d "$target_dir" ] && mkdir -p "$target_dir"

  (cd "$BINDIR" && moon clean 2>&1)
  build_binary

  local install_path="$target_dir/mmprocess"
  cp "$BINARY" "$install_path"
  chmod +x "$install_path"
  echo "Installed: $install_path" >&2

  # Also install the shell wrapper
  local wrapper_path="$target_dir/moonmacro.sh"
  cp "$0" "$wrapper_path"
  chmod +x "$wrapper_path"
  echo "Installed: $wrapper_path" >&2

  echo "" >&2
  echo "Now run from anywhere:" >&2
  echo "  mmprocess src/" >&2
  echo "  moonmacro.sh src/" >&2
}

if [ "${1:-}" = "install" ]; then
  install_binary "${2:-}"
  exit 0
fi

BIN="$(find_binary)"
if [ -z "$BIN" ]; then
  build_binary
  BIN="$BINARY"
fi

process_file() {
  local input="$1"
  local output="${input%.macro}"

  if [ ! -f "$input" ]; then
    echo "error: not a file: $input" >&2
    return 1
  fi

  local result
  result=$("$BIN" "$(cat "$input")") || {
    echo "error: processing $input" >&2
    return 1
  }

  echo "$result" > "$output"
  echo "  $input -> $output"
}

count=0
for arg in "${@:-.}"; do
  if [ -d "$arg" ]; then
    while IFS= read -r -d '' f; do
      process_file "$f"
      count=$((count + 1))
    done < <(find "$arg" -name '*.mbt.macro' -type f -print0)
  elif [ -f "$arg" ]; then
    process_file "$arg"
    count=$((count + 1))
  else
    echo "error: not found: $arg" >&2
    exit 1
  fi
done
if [ $count -eq 0 ]; then
  echo "no .mbt.macro files found" >&2
fi

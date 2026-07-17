#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Clean previous outputs
rm -f lib/e2e_*/test.mbt

# Preprocess ALL e2e packages first
echo "  [e2e] preprocessing..."
bash moonmacro.sh lib/ > /dev/null 2>&1

# Build entire project once
echo "  [e2e] building..."
if ! moon build --target native 2>&1; then
  echo "  FAIL: compilation error"
  exit 1
fi

PASS=0
FAIL=0

check() {
  local name="$1"
  local expected="$2"
  echo "  [e2e] $name ... "

  local bin="_build/native/debug/build/lib/${name}/${name}.exe"
  if [ ! -f "$bin" ]; then
    echo "    FAIL: binary not found"
    FAIL=$((FAIL + 1))
    return 1
  fi

  local actual
  actual=$("$bin" 2>&1)
  if [ "$actual" != "$expected" ]; then
    echo "    FAIL: expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
    return 1
  fi

  echo "    PASS"
  PASS=$((PASS + 1))
}

check "e2e_constructor" "1,2"
check "e2e_getters" "42"
check "e2e_enum_from_str" "Red ok
Blue ok"

echo ""
echo "e2e results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

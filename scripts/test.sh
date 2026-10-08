#!/usr/bin/env bash
# Runs terraform test in every module and in bootstrap/. Exits non-zero on any failure.
set -euo pipefail
cd "$(dirname "$0")/.."

dirs=()
for d in modules/* bootstrap; do
  [[ -d "$d/tests" ]] && dirs+=("$d")
done

if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "no test directories found" >&2
  exit 1
fi

for d in "${dirs[@]}"; do
  echo "==> $d"
  terraform -chdir="$d" init -backend=false -input=false >/dev/null
  terraform -chdir="$d" test
done

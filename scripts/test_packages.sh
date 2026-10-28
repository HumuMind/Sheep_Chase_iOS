#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for package in SheepChaseCore SheepChasePersistence SheepChaseUI SheepChaseExport SheepChaseBattleEngine; do
  echo "==> $package"
  swift test --package-path "Packages/$package" --disable-sandbox
done

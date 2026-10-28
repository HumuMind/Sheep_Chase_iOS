#!/usr/bin/env python3
"""Fail if a Swift file exceeds the hard limit, warn above the soft limit."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOFT_LIMIT = 400
HARD_LIMIT = 500
FOLDERS = ("SheepChase", "SheepChaseTests", "SheepChaseUITests", "Packages")

rows = []
for folder in FOLDERS:
    for path in (ROOT / folder).rglob("*.swift"):
        if ".build" in path.parts or ".swiftpm" in path.parts:
            continue
        rows.append((len(path.read_text(encoding="utf-8").splitlines()), path))

rows.sort(reverse=True)
failures = [(n, p) for n, p in rows if n > HARD_LIMIT]
warnings = [(n, p) for n, p in rows if SOFT_LIMIT < n <= HARD_LIMIT]

for n, p in rows[:10]:
    print(f"{n:4d}  {p.relative_to(ROOT)}")
print(f"\n文件数：{len(rows)}；软上限 {SOFT_LIMIT} 行，硬上限 {HARD_LIMIT} 行")
for n, p in warnings:
    print(f"WARN  {n:4d}  {p.relative_to(ROOT)}")
for n, p in failures:
    print(f"FAIL  {n:4d}  {p.relative_to(ROOT)}")

if failures:
    raise SystemExit(1)

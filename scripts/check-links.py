#!/usr/bin/env python3
"""Verify relative markdown links resolve to existing files.

Scans the living docs (not historical records under tests/records/ or
vendor/) for ](relative/path) links and fails naming every dead one —
the guard that would have caught the README plugin-badge link rot.
"""
import glob
import os
import re
import sys

FILES = ["README.md", "CONTRIBUTING.md", "CHANGELOG.md", "tests/README.md",
         "tests/RUNBOOK.md"] + sorted(glob.glob("docs/*.md"))
LINK = re.compile(r"\]\((?!https?://|#|mailto:)([^)\s]+?)(?:#[^)]*)?\)")

dead = []
for f in FILES:
    with open(f, encoding="utf-8") as fh:
        text = fh.read()
    for m in LINK.finditer(text):
        target = os.path.normpath(os.path.join(os.path.dirname(f), m.group(1)))
        if not os.path.exists(target):
            dead.append(f"{f} -> {m.group(1)}")

if dead:
    print("DEAD LINKS:")
    for d in dead:
        print(" ", d)
    sys.exit(1)
print(f"links OK ({len(FILES)} files scanned)")

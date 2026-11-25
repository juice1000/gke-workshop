#!/usr/bin/env python3
"""Python-Syntax und lokale Markdown-Dateiverweise ohne Zusatzpakete pruefen."""
import ast
from pathlib import Path
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
errors = []
for folder in ("scripts", "tests"):
    for file in (ROOT / folder).rglob("*.py"):
        ast.parse(file.read_text(), filename=str(file))
for file in [ROOT / "README.md", ROOT / "AGENTS.md", *ROOT.glob("lab*/**/*.md"),
             *ROOT.glob("docs/*.md")]:
    text = file.read_text()
    if "\u2014" in text and file.name not in {"01-kontext.md", "02-bedarf-und-lernziele.md", "03-curriculum-entscheidungen.md", "04-lernumgebung-und-offene-punkte.md", "05-gespraechsnotizen.md"}:
        errors.append(f"{file.relative_to(ROOT)}: Gedankenstrich")
    for link in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
        if "://" in link or link.startswith("#"):
            continue
        target = unquote(link.split("#")[0])
        if target and not (file.parent / target).exists():
            errors.append(f"{file.relative_to(ROOT)}: Verweis fehlt: {target}")
if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print("OK: Python-Syntax und lokale Markdown-Verweise")

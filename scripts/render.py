#!/usr/bin/env python3
"""Image-Platzhalter ersetzen. Schreibt nur neue Dateien, aendert keinen Cluster."""
import argparse
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--image", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._/:@+-]*", args.image):
        parser.error("Ungueltiger Image-Name (keine Leerzeichen oder YAML-Sonderzeichen).")
    source, output = args.source.resolve(), args.output.resolve()
    if not source.is_dir():
        parser.error("Quellordner fehlt.")
    if output == source or source in output.parents:
        parser.error("Ausgabe muss ausserhalb des Quellordners liegen.")
    files = sorted(source.rglob("*.yaml"))
    if not files:
        parser.error("Keine YAML-Dateien gefunden.")
    targets = [(file, output / file.relative_to(source)) for file in files]
    if any(target.exists() for _, target in targets):
        parser.error("Ausgabedateien existieren bereits. Anderen --output-Ordner waehlen.")
    for file, target in targets:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(file.read_text().replace("WORKSHOP_IMAGE", args.image))
    print(f"OK: {len(files)} Manifeste nach {output} geschrieben. Noch nichts ausgerollt.")


if __name__ == "__main__":
    main()

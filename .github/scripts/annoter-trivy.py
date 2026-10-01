#!/usr/bin/env python3
"""Transforme un rapport Trivy (JSON) en annotations GitHub, puis échoue s'il y a des vulnérabilités.

Usage : annoter-trivy.py rapport.json composant
"""
import json
import sys

rapport, composant = sys.argv[1], sys.argv[2]
with open(rapport, encoding="utf-8") as f:
    donnees = json.load(f)

vulnerabilites = [
    (cible.get("Target", "?"), v)
    for cible in donnees.get("Results") or []
    for v in cible.get("Vulnerabilities") or []
]

for cible, v in vulnerabilites:
    print(
        f"::error title=Image {composant} : {v['VulnerabilityID']} ({v.get('Severity')})::"
        f"{v.get('PkgName')} {v.get('InstalledVersion')} → corrigé en {v.get('FixedVersion') or '?'}"
        f" · {cible} · {v.get('Title', '')}"
    )

print(f"{len(vulnerabilites)} vulnérabilité(s) critique(s) corrigible(s) dans l'image {composant}")
sys.exit(1 if vulnerabilites else 0)

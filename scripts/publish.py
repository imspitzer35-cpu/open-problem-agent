#!/usr/bin/env python3
"""Publish one gated paper dir to Zenodo (DOI). Usage: publish.py [--dry-run] papers/<slug>"""
import html
import json
import os
import sys
import urllib.request
from pathlib import Path

API = os.environ.get("ZENODO_API", "https://zenodo.org/api")  # sandbox: https://sandbox.zenodo.org/api
AUTHOR = os.environ.get("PAPER_AUTHOR", "Lederer, Alexander")
REPO = "https://github.com/" + os.environ.get("GITHUB_REPOSITORY", "imspitzer35-cpu/open-problem-agent")
DISCLOSURE = (
    "<p><b>AI disclosure:</b> The problem was selected, solved, formalized and written up autonomously by an "
    "AI agent (Claude Opus 5.5, Anthropic). No human checked the proof by hand. Correctness rests on the "
    "machine-checked Lean 4 / Mathlib proof included in this record and in the source repository.</p>"
)


def metadata(meta):
    return {"metadata": {
        "upload_type": "publication",
        "publication_type": "preprint",
        "title": meta["title"],
        "creators": [{"name": AUTHOR}],
        "description": f"<p>{html.escape(meta['abstract'])}</p>{DISCLOSURE}",
        "keywords": meta.get("keywords", []),
        "license": "cc-by-4.0",
        "related_identifiers": [{"identifier": REPO, "relation": "isSupplementedBy", "resource_type": "software"}],
    }}


def call(method, url, body=None, ctype="application/json"):
    req = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": f"Bearer {os.environ['ZENODO_TOKEN']}", "Content-Type": ctype})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def main(argv):
    dry = "--dry-run" in argv
    d = Path([a for a in argv if not a.startswith("--")][0])
    meta = json.loads((d / "meta.json").read_text())
    files = [d / "paper.pdf", d / "paper.tex", Path(meta["module"].replace(".", "/") + ".lean")]
    md = metadata(meta)
    if dry:
        print(json.dumps(md, indent=1), *files, sep="\n")
        assert md["metadata"]["creators"] and "AI disclosure" in md["metadata"]["description"]
        return
    if (d / "PUBLISHED.json").exists():
        sys.exit(f"already published: {d}")
    dep = call("POST", f"{API}/deposit/depositions", b"{}")
    for f in files:
        call("PUT", f"{dep['links']['bucket']}/{f.name}", f.read_bytes(), "application/octet-stream")
    call("PUT", dep["links"]["self"], json.dumps(md).encode())
    pub = call("POST", dep["links"]["publish"])
    url = f"https://doi.org/{pub['doi']}"
    (d / "PUBLISHED.json").write_text(json.dumps({"doi": pub["doi"], "url": url, "record": pub["links"]["html"]}, indent=1))
    print(url)


if __name__ == "__main__":
    main(sys.argv[1:])

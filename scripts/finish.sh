#!/usr/bin/env bash
# All publish gates for one READY paper: Lean -> PDF -> independent review -> Zenodo -> issue with X draft.
# Usage: scripts/finish.sh papers/<slug>
set -uo pipefail
d=${1%/}
fail() { printf '%s\n' "$1" > "$d/GATE_FAIL.md"; rm -f "$d/READY"; echo "GATE FAIL $d"; exit 1; }
rm -f "$d/GATE_FAIL.md" review.json

out=$(scripts/gate.sh "$d" 2>&1) || fail "Lean gate failed:
$out"

command -v latexmk >/dev/null || sudo apt-get install -yqq latexmk texlive-latex-extra texlive-science texlive-fonts-recommended >/dev/null
out=$(cd "$d" && latexmk -pdf -interaction=nonstopmode -halt-on-error paper.tex 2>&1) || fail "LaTeX build failed:
$(printf '%s' "$out" | tail -30)"

LEFT=2700 scripts/claude.sh "$(cat REVIEW_PROMPT.md)

Paper directory: $d"
python3 - "$d" <<'EOF' || fail "Independent review rejected or missing, see REVIEW_REJECTED.json"
import json, shutil, sys
d = sys.argv[1]
try:
    r = json.load(open("review.json"))
except Exception as e:
    json.dump({"error": f"no valid review.json: {e}"}, open(f"{d}/REVIEW_REJECTED.json", "w")); sys.exit(1)
ok = all(r.get(k) is True for k in ("statement_matches", "problem_open", "no_prior_solution", "proof_sound", "ai_disclosed"))
shutil.move("review.json", f"{d}/REVIEW.json" if ok else f"{d}/REVIEW_REJECTED.json")
sys.exit(0 if ok else 1)
EOF

url=$(python3 scripts/publish.py "$d") || { echo "Zenodo publish failed for $d (will retry next shift)"; exit 1; }
rm -f "$d/READY"
post=$(sed "s#{DOI_URL}#$url#g" "$d/x-post.md" 2>/dev/null)
gh issue create --title "Published: $(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["title"])' "$d/meta.json")" \
  --body "DOI: $url

X-Post-Entwurf (nicht gepostet):

$post" || true

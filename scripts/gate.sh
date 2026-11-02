#!/usr/bin/env bash
# Lean gate for one paper dir: the module builds, uses no banned constructs,
# and its main theorem depends only on propext, Classical.choice, Quot.sound.
# Usage: scripts/gate.sh papers/<slug>
# ponytail: grep ban list + #print axioms; upgrade to lean4checker/comparator if an agent ever games it.
set -euo pipefail
read -r mod thm < <(python3 - "$1/meta.json" <<'EOF'
import json, re, sys
m = json.load(open(sys.argv[1]))
for k in ("module", "theorem"):
    assert re.fullmatch(r"[A-Za-z0-9_.']+", m[k]), f"bad {k}: {m[k]!r}"
assert m["module"].startswith("Research."), "module must live under Research."
print(m["module"], m["theorem"])
EOF
)
[ -n "${thm:-}" ] || { echo "GATE FAIL: bad meta.json"; exit 1; }
path=${mod//.//}
banned='sorry|admit|axiom|opaque|native_decide|implemented_by|extern|unsafe|elab|macro|macro_rules|syntax|initialize|builtin_initialize|skipKernelTC|#exit'
if grep -rnwE "$banned" "$path.lean" $( [ -d "$path" ] && echo "$path" ) --include='*.lean'; then
  echo "GATE FAIL: banned construct in $path"; exit 1
fi
lake build "$mod"
f=$(mktemp -d)/Check.lean
printf 'import %s\n#print axioms %s\n' "$mod" "$thm" > "$f"
out=$(lake env lean "$f" 2>&1) || { echo "$out"; echo "GATE FAIL: axiom check did not run"; exit 1; }
echo "$out"
python3 - "$out" <<'EOF'
import re, sys
out = sys.argv[1]
if "does not depend on any axioms" in out:
    sys.exit(0)
m = re.search(r"depends on axioms: \[(.*?)\]", out, re.S)
extra = {a.strip() for a in m.group(1).split(",")} - {"propext", "Classical.choice", "Quot.sound"} if m else {"<no axiom report>"}
sys.exit(f"GATE FAIL: non-standard axioms {sorted(extra)}" if extra else 0)
EOF
echo "GATE OK: $thm"

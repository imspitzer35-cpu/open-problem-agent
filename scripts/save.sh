#!/usr/bin/env bash
# Commit + push the agent's work. Pipeline files are reset first, so the agent cannot change its own gates.
for p in scripts .github tests PROMPT.md REVIEW_PROMPT.md lakefile.toml lean-toolchain lake-manifest.json \
         Research/SelftestGood.lean Research/SelftestBad.lean Research/SelftestAxiom.lean; do
  git checkout -q HEAD -- "$p" 2>/dev/null
done
git clean -fdq -- scripts .github tests
git add -A
git -c user.name=research-bot -c user.email=research-bot@users.noreply.github.com commit -qm "$1" || exit 0
git pull -q --rebase && git push -q

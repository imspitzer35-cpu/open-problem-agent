#!/usr/bin/env bash
# Commit the agent's work; push only where a GitHub token is present (Publish step).
# Pipeline files are reset to the commit this run started from, so the agent cannot change its own gates.
ref=${GITHUB_SHA:-HEAD}
for p in scripts .github tests PROMPT.md REVIEW_PROMPT.md lakefile.toml lean-toolchain lake-manifest.json \
         Research/SelftestGood.lean Research/SelftestBad.lean Research/SelftestAxiom.lean; do
  git checkout -q "$ref" -- "$p" 2>/dev/null
done
git clean -fdq -- scripts .github tests
git add -A
git -c user.name=research-bot -c user.email=research-bot@users.noreply.github.com commit -qm "$1"
[ -n "${GH_TOKEN:-}" ] || exit 0
url="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git pull -q --rebase "$url" "$GITHUB_REF_NAME" && git push -q "$url" "HEAD:$GITHUB_REF_NAME"

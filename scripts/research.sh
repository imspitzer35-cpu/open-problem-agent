#!/usr/bin/env bash
# One shift (~5 h): research sessions until time or all accounts are used up, then try to publish READY papers.
set -uo pipefail
npm i -g @anthropic-ai/claude-code >/dev/null 2>&1
end=$((SECONDS + ${RESEARCH_MIN:-280} * 60))
while (( SECONDS < end - 300 )); do
  LEFT=$((end - SECONDS)) scripts/claude.sh "$(cat PROMPT.md)"; code=$?
  scripts/save.sh "research: progress"
  (( code == 75 )) && break
  (( code != 0 )) && sleep 120
done
for d in papers/*/; do
  [ -f "$d/READY" ] && [ ! -f "$d/PUBLISHED.json" ] && scripts/finish.sh "$d"
done
scripts/save.sh "publish: gate results"

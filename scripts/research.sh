#!/usr/bin/env bash
# Research part of a shift (~4.7 h): sessions until time is up or all accounts are at their limit.
# Commits stay local; the Publish step (which has the tokens) runs the gates and pushes.
set -uo pipefail
npm i -g @anthropic-ai/claude-code >/dev/null 2>&1
end=$((SECONDS + ${RESEARCH_MIN:-280} * 60))
while (( SECONDS < end - 300 )); do
  LEFT=$((end - SECONDS)) scripts/claude.sh "$(cat PROMPT.md)"; code=$?
  scripts/save.sh "research: progress"
  (( code == 75 )) && break
  (( code != 0 )) && sleep 120
done
true

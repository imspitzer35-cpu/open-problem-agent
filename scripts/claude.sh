#!/usr/bin/env bash
# Run one headless Claude session; on usage limit rotate ALEX -> SEEL -> KILI.
# Usage: LEFT=<seconds> scripts/claude.sh "<prompt>"   exit 75 = all accounts at limit
# ponytail: limit detected by message text; if the wording changes, rotation stops and the shift just ends early.
for name in ALEX SEEL KILI; do
  var="CLAUDE_TOKEN_$name"; tok="${!var:-}"
  [ -z "$tok" ] && continue
  out=$(CLAUDE_CODE_OAUTH_TOKEN="$tok" timeout "${LEFT:-3600}" claude -p "$1" \
    --model claude-opus-5-5 --effort medium --permission-mode auto 2>&1); code=$?
  printf '%s\n' "$out" | tail -40
  if printf '%s' "$out" | grep -qiE 'usage limit|hit your limit|limit reached|rate.?limit'; then
    echo "== $name at limit, next account"; continue
  fi
  exit $code
done
echo "== all accounts at limit"; exit 75

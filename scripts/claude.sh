#!/usr/bin/env bash
# Run one headless Claude session; on usage limit or error rotate ALEX -> SEEL -> KILI.
# Usage: LEFT=<seconds> scripts/claude.sh "<prompt>"   exit 75 = no account could run it
# LEFT is a shared deadline for all attempts. Publish/push tokens are stripped from the session.
# ponytail: limit detected by message text; if the wording changes, it rotates only on non-zero exit.
deadline=$((SECONDS + ${LEFT:-3600}))
for name in ALEX SEEL KILI; do
  var="CLAUDE_TOKEN_$name"; tok="${!var:-}"
  [ -z "$tok" ] && continue
  (( SECONDS < deadline - 60 )) || break
  out=$(env -u ZENODO_TOKEN -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_TOKEN_ALEX -u CLAUDE_TOKEN_SEEL -u CLAUDE_TOKEN_KILI \
    CLAUDE_CODE_OAUTH_TOKEN="$tok" timeout $((deadline - SECONDS)) claude -p "$1" \
    --model claude-opus-5-5 --effort medium --permission-mode auto 2>&1); code=$?
  printf '%s\n' "$out" | tail -40
  if (( code != 0 )) || printf '%s' "$out" | grep -qiE 'usage limit|hit your limit|limit reached'; then
    echo "== $name failed (exit $code) or at limit, next account"; continue
  fi
  exit 0
done
echo "== no account left"; exit 75

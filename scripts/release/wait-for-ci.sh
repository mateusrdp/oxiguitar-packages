#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Waits for the `ci-success` check on a commit of OWNER/REPO, and fails
# unless it passes. Used by the Release workflow.
#
# Most red `ci-success` checks during a release were not the code: a slow
# Ubuntu mirror, a macOS runner that was cancelled before it started, a 503
# from GitHub. Each passed when its failed jobs were run again (24 Nov 2026:
# 0.21.8 stopped on a mirror and passed on the rerun). So when `ci-success`
# fails, this runs the failed jobs of its workflow run again, up to RERUNS
# times, and goes on waiting; a real failure fails every time and still
# stops the release.
#
# Reading needs only GH_TOKEN (the workflow's own token reads a public
# repository). Running jobs again needs the GitHub App's Actions permission:
# a token is made from RELEASE_APP_ID and RELEASE_APP_KEY just before each
# rerun, as an app token lasts an hour and the wait can be longer. Without
# them, or without that permission, the first failure stops the wait, as
# before.
#
# Usage: wait-for-ci.sh SHA MINUTES [RERUNS]
#   MINUTES 0 looks once (a dry run); RERUNS defaults to 2.
# Environment: OWNER, REPO, GH_TOKEN; RELEASE_APP_ID and RELEASE_APP_KEY for
# reruns. GITHUB_API (default https://api.github.com) and WAIT_SECONDS
# (default 60) are for the tests.

set -euo pipefail

(( $# >= 2 )) || { echo "usage: $0 SHA MINUTES [RERUNS]" >&2; exit 2; }
sha="$1"
minutes="$2"
reruns="${3:-2}"
api="${GITHUB_API:-https://api.github.com}"
pause="${WAIT_SECONDS:-60}"
: "${OWNER:?}" "${REPO:?}"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# Prints an installation token of the GitHub App for REPO that may run
# workflows again (Actions: write), or fails.
app_token() {
  [[ -n "${RELEASE_APP_ID:-}" && -n "${RELEASE_APP_KEY:-}" ]] || return 1
  local now header payload signature jwt installation
  now="$(date +%s)"
  header="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)"
  payload="$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' $((now - 60)) $((now + 540)) "$RELEASE_APP_ID" | b64url)"
  signature="$(printf '%s.%s' "$header" "$payload" \
    | openssl dgst -sha256 -sign <(printf '%s\n' "$RELEASE_APP_KEY") | b64url)"
  jwt="$header.$payload.$signature"
  installation="$(curl -fsS -H "Authorization: Bearer $jwt" -H 'Accept: application/vnd.github+json' \
    "$api/repos/$OWNER/$REPO/installation" | jq -er .id)" || return 1
  jq -n --arg repo "$REPO" '{repositories: [$repo], permissions: {actions: "write"}}' \
    | curl -fsS -X POST -H "Authorization: Bearer $jwt" -H 'Accept: application/vnd.github+json' \
      --data @- "$api/app/installations/$installation/access_tokens" \
    | jq -er .token
}

# Runs the failed (and cancelled) jobs of the workflow run that holds the
# check suite SUITE again.
rerun() {
  local suite="$1" run token
  run="$(gh api "repos/$OWNER/$REPO/actions/runs?head_sha=$sha&per_page=100" \
    --jq "[.workflow_runs[] | select(.check_suite_id == $suite)] | first | .id // empty")"
  [[ -n "$run" ]] || { echo "::warning::no workflow run found for ci-success on ${sha:0:7}"; return 1; }
  token="$(app_token)" || {
    echo "::warning::no token to run the jobs again: give the GitHub App \"Actions: Read and write\" (RELEASING.md)"
    return 2
  }
  GH_TOKEN="$token" gh api -X POST "repos/$OWNER/$REPO/actions/runs/$run/rerun-failed-jobs" > /dev/null \
    || { echo "::warning::could not run the failed jobs of run $run again (still finishing?)"; return 1; }
  echo "::notice::ci-success on ${sha:0:7} failed: running the failed jobs of https://github.com/$OWNER/$REPO/actions/runs/$run again"
}

deadline=$((SECONDS + minutes * 60))
misses=0   # rerun requests that did not go through
stale=""   # the id of a failed ci-success already rerun: pending until a new one shows
while :; do
  read -r id conclusion suite < <(gh api "repos/$OWNER/$REPO/commits/$sha/check-runs?check_name=ci-success&per_page=100" \
    --jq '[.check_runs[]] | first | "\(.id // "-") \(.conclusion // "pending") \(.check_suite.id // "-")"')
  [[ "$id" == "$stale" ]] && conclusion=pending
  case "$conclusion" in
    success) echo "ci-success on ${sha:0:7} passed"; exit 0 ;;
    pending) ;;
    *)
      if (( reruns > 0 && SECONDS < deadline )); then
        status=0
        rerun "$suite" || status=$?
        if (( status == 0 )); then
          stale="$id"
          reruns=$((reruns - 1))
        elif (( status == 2 || ++misses >= 5 )); then
          echo "::error::ci-success on ${sha:0:7} is $conclusion"; exit 1
        fi
      else
        echo "::error::ci-success on ${sha:0:7} is $conclusion"; exit 1
      fi
      ;;
  esac
  (( SECONDS < deadline )) || { echo "::error::ci-success on ${sha:0:7} did not finish in time"; exit 1; }
  sleep "$pause"
done

#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Tries scripts/release/wait-for-ci.sh against stand-ins for `gh` and `curl`
# that answer from a script of check results: a green CI, a red one that
# passes when its failed jobs run again, a red one that stays red, no app
# key, a dry run, and a rerun that GitHub keeps refusing. Run by CI.
set -euo pipefail

wait_for_ci="$(cd "$(dirname "$0")/.." && pwd)/scripts/release/wait-for-ci.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }

mkdir "$work/bin"
# gh: check-runs answers with the first line of $STATE/checks ("ID CONCLUSION
# SUITE"), dropping it while more lines follow; the run list answers run 77
# for suite 9; a rerun is logged with the token it was made with, and fails
# while $STATE/refuse exists.
cat > "$work/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
case "$args" in
  *"-X POST"*rerun-failed-jobs*)
    echo "rerun ${args##*/runs/} $GH_TOKEN" >> "$STATE/log"
    [[ ! -e "$STATE/refuse" ]] ;;
  *check-runs*)
    head -n 1 "$STATE/checks"
    if (( $(wc -l < "$STATE/checks") > 1 )); then sed -i 1d "$STATE/checks"; fi ;;
  *actions/runs\?head_sha*) echo 77 ;;
  *) echo "unexpected gh $args" >&2; exit 1 ;;
esac
EOF
# curl: the app's installation, and its token once the JWT checks out with
# the app's public key.
cat > "$work/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
auth=""; url=""
while (( $# )); do
  case "$1" in
    -H) [[ "$2" == Authorization:* ]] && auth="${2#Authorization: Bearer }"; shift 2 ;;
    --data|-X) shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
IFS=. read -r h p s <<< "$auth"
unb64() { local x; x="$(tr -- '-_' '+/')"; while (( ${#x} % 4 )); do x+="="; done; printf '%s' "$x" | openssl base64 -d -A; }
printf '%s.%s' "$h" "$p" | openssl dgst -sha256 -verify "$STATE/public.pem" -signature <(printf '%s' "$s" | unb64) > /dev/null \
  || { echo "bad JWT" >&2; exit 22; }
printf '%s' "$p" | unb64 | jq -e '.iss == "4242"' > /dev/null || { echo "bad issuer" >&2; exit 22; }
case "$url" in
  */repos/*/installation) echo '{"id": 5}' ;;
  */app/installations/5/access_tokens) echo '{"token": "app-token"}' ;;
  *) echo "unexpected curl $url" >&2; exit 22 ;;
esac
EOF
chmod +x "$work/bin/gh" "$work/bin/curl"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$work/key.pem" 2> /dev/null
openssl pkey -in "$work/key.pem" -pubout -out "$work/public.pem"

export PATH="$work/bin:$PATH" OWNER=owner REPO=repo GH_TOKEN=read-token WAIT_SECONDS=0
key="$(cat "$work/key.pem")"

case_() {  # NAME, then the check results, one per line, on stdin
  name="$1"
  export STATE="$work/$name"
  mkdir "$STATE"
  cp "$work/public.pem" "$STATE/"
  cat > "$STATE/checks"
  : > "$STATE/log"
}
reruns() { grep -c '^rerun' "$STATE/log" || true; }

case_ green <<< "1 success 9"
RELEASE_APP_ID=4242 RELEASE_APP_KEY="$key" "$wait_for_ci" abcdef0 5 > /dev/null || fail "green"
[[ "$(reruns)" == 0 ]] || fail "green: ran jobs again"

case_ rerun-passes <<'T'
- pending -
1 failure 9
1 failure 9
2 pending 9
2 success 9
T
RELEASE_APP_ID=4242 RELEASE_APP_KEY="$key" "$wait_for_ci" abcdef0 5 > "$STATE/out" || fail "rerun-passes: $(cat "$STATE/out")"
[[ "$(cat "$STATE/log")" == "rerun 77/rerun-failed-jobs app-token" ]] || fail "rerun-passes: $(cat "$STATE/log")"

case_ stays-red <<'T'
1 failure 9
2 failure 9
3 failure 9
T
if RELEASE_APP_ID=4242 RELEASE_APP_KEY="$key" "$wait_for_ci" abcdef0 5 > "$STATE/out"; then fail "stays-red passed"; fi
[[ "$(reruns)" == 2 ]] || fail "stays-red: $(reruns) reruns"
grep -q '::error::ci-success on abcdef0 is failure' "$STATE/out" || fail "stays-red: $(cat "$STATE/out")"

case_ no-key <<< "1 cancelled 9"
if "$wait_for_ci" abcdef0 5 > "$STATE/out"; then fail "no-key passed"; fi
[[ "$(reruns)" == 0 ]] || fail "no-key: ran jobs again"
grep -q 'Actions: Read and write' "$STATE/out" || fail "no-key: $(cat "$STATE/out")"

case_ dry-run <<< "1 failure 9"
if RELEASE_APP_ID=4242 RELEASE_APP_KEY="$key" "$wait_for_ci" abcdef0 0 0 > /dev/null; then fail "dry-run passed"; fi
[[ "$(reruns)" == 0 ]] || fail "dry-run: ran jobs again"

case_ refused <<< "1 failure 9"
touch "$STATE/refuse"
if RELEASE_APP_ID=4242 RELEASE_APP_KEY="$key" "$wait_for_ci" abcdef0 5 > /dev/null; then fail "refused passed"; fi
[[ "$(reruns)" == 5 ]] || fail "refused: asked $(reruns) times"

echo "wait-for-ci: all cases passed"

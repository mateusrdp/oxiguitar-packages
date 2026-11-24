#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Tries scripts/apt-install.sh against a stand-in `apt-get` that downloads
# into a folder at the pace a test asks for: a slow download that takes
# longer than the stall limit but keeps growing (it must be let finish), a
# download that gets stuck (stopped, the mirror list turned, tried again), a
# mirror that stays stuck (the tries run out), an apt error, and
# --recommends. Run by CI.
set -euo pipefail

apt_install="$(cd "$(dirname "$0")/.." && pwd)/scripts/apt-install.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }

mkdir "$work/bin"
printf '#!/usr/bin/env bash\nexec "$@"\n' > "$work/bin/sudo"
# apt-get: each call takes the first line of $STATE/plan (the last line
# stays for every call after it) and logs its arguments.
#   grow N   writes a byte every half second, N times, and succeeds
#   stuck    writes a byte, then hangs
#   fail     fails at once
cat > "$work/bin/apt-get" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STATE/log"
step="$(head -n 1 "$STATE/plan")"
if (( $(wc -l < "$STATE/plan") > 1 )); then sed -i 1d "$STATE/plan"; fi
case "$step" in
  grow*) for (( i = 0; i < ${step#grow }; i++ )); do printf x >> "$STATE/apt/file"; sleep 0.5; done ;;
  stuck) printf x >> "$STATE/apt/file"; exec sleep 600 ;;
  fail) exit 100 ;;
esac
EOF
chmod +x "$work/bin/sudo" "$work/bin/apt-get"

export PATH="$work/bin:$PATH" APT_STALL_SECONDS=2 APT_CHECK_SECONDS=1 APT_PAUSE_SECONDS=0

case_() {  # NAME, then the plan, one step per line, on stdin
  export STATE="$work/$1"
  mkdir -p "$STATE/apt"
  cat > "$STATE/plan"
  : > "$STATE/log"
  printf 'http://first/ubuntu/\tpriority:1\nhttp://second/ubuntu/\tpriority:2\n' > "$STATE/mirrors"
  export APT_WATCH_DIRS="$STATE/apt" APT_MIRRORS="$STATE/mirrors"
}
calls() { sed -E 's/(-o [^ ]+ )+//' "$STATE/log" | awk '{ print $1 }' | paste -sd ' '; }

# 4 seconds of download with a stall limit of 2: slow, never stuck.
case_ slow <<'T'
grow 2
grow 8
grow 1
T
"$apt_install" pkg > "$STATE/out" 2>&1 || fail "slow: $(cat "$STATE/out")"
[[ "$(calls)" == "update install install" ]] || fail "slow: calls $(calls)"
grep -q -- '--download-only pkg' "$STATE/log" || fail "slow: no download-only call"
! grep -q '::warning::' "$STATE/out" || fail "slow: $(cat "$STATE/out")"

case_ stuck-once <<'T'
grow 1
stuck
grow 1
grow 1
grow 1
T
"$apt_install" pkg > "$STATE/out" 2>&1 || fail "stuck-once: $(cat "$STATE/out")"
[[ "$(calls)" == "update install update install install" ]] || fail "stuck-once: calls $(calls)"
grep -q 'downloaded nothing for 2 seconds' "$STATE/out" || fail "stuck-once: $(cat "$STATE/out")"
grep -q 'apt finished on try 2' "$STATE/out" || fail "stuck-once: $(cat "$STATE/out")"
[[ "$(head -n 1 "$STATE/mirrors")" == "$(printf 'http://second/ubuntu/\tpriority:1')" ]] \
  || fail "stuck-once: mirrors $(cat "$STATE/mirrors")"
! pgrep -f 'sleep 600' > /dev/null || fail "stuck-once: the stuck apt-get is still running"

case_ stays-stuck <<< "stuck"
if APT_TRIES=2 "$apt_install" pkg > "$STATE/out" 2>&1; then fail "stays-stuck passed"; fi
[[ "$(calls)" == "update update" ]] || fail "stays-stuck: calls $(calls)"
grep -q '::error::apt failed 2 times: pkg' "$STATE/out" || fail "stays-stuck: $(cat "$STATE/out")"
pkill -f 'sleep 600' || true

case_ error <<'T'
fail
grow 1
T
"$apt_install" pkg > "$STATE/out" 2>&1 || fail "error: $(cat "$STATE/out")"
[[ "$(calls)" == "update update install install" ]] || fail "error: calls $(calls)"

case_ recommends <<< "grow 1"
"$apt_install" --recommends pkg > "$STATE/out" 2>&1 || fail "recommends: $(cat "$STATE/out")"
! grep -q -- '--no-install-recommends' "$STATE/log" || fail "recommends: $(cat "$STATE/log")"
case_ no-recommends <<< "grow 1"
"$apt_install" pkg > "$STATE/out" 2>&1 || fail "no-recommends: $(cat "$STATE/out")"
[[ "$(grep -c -- '--no-install-recommends' "$STATE/log")" == 2 ]] || fail "no-recommends: $(cat "$STATE/log")"

echo "apt-install: all cases passed"

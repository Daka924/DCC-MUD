#!/usr/bin/env bash
# Starts a dedicated server and two headless bot players, then checks that
# they saw each other, formed a party and that the invention engine fired.
# Usage: GODOT=/path/to/godot tests/multiplayer_smoke.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
PORT=24777
OUT="$(mktemp -d)"
"$GODOT" --headless --path . -- --server --port=$PORT --seed=42 >"$OUT/server.log" 2>&1 &
SERVER=$!
sleep 2
timeout 40 "$GODOT" --headless --path . -- --bot --name=Ann --port=$PORT --seconds=14 >"$OUT/ann.log" 2>&1 &
A=$!
timeout 40 "$GODOT" --headless --path . -- --bot --passive --name=Bo --port=$PORT --seconds=14 >"$OUT/bo.log" 2>&1 &
B=$!
wait $A; wait $B
kill $SERVER 2>/dev/null
grep -HE "ERROR" "$OUT"/*.log | sed "s|$OUT/||"
cat "$OUT"/*.log | grep -E "^BOT|ERROR|Server listening"
fail=0
grep -q "ERROR" "$OUT"/*.log && { echo "FAIL: errors in logs"; fail=1; }
for bot in ann bo; do
  grep -q "players_seen=2" "$OUT/$bot.log" || { echo "FAIL: $bot did not see the other player"; fail=1; }
  grep -q "party=2" "$OUT/$bot.log" || { echo "FAIL: $bot is not in a party of two"; fail=1; }
done
grep -qE "abilities=\[\"" "$OUT/ann.log" || { echo "FAIL: ann did not make a discovery"; fail=1; }
[ $fail -eq 0 ] && echo "multiplayer smoke test passed"
exit $fail

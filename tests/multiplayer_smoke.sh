#!/usr/bin/env bash
# Starts a dedicated server and three headless bot players over the network.
# Ann and Bo start in the same place and should find each other and form a
# party. Cy starts alone elsewhere and should recruit the local NPC companion.
# Usage: GODOT=/path/to/godot tests/multiplayer_smoke.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
PORT=24777
OUT="$(mktemp -d)"
"$GODOT" --headless --path . -- --server --port=$PORT --seed=42 >"$OUT/server.log" 2>&1 &
SERVER=$!
sleep 2
PIDS=""
timeout 40 "$GODOT" --headless --path . -- --bot --name=Ann --past=plumber --start=0 --port=$PORT --seconds=14 >"$OUT/ann.log" 2>&1 &
PIDS="$PIDS $!"
timeout 40 "$GODOT" --headless --path . -- --bot --passive --name=Bo --past=karaoke --start=0 --port=$PORT --seconds=14 >"$OUT/bo.log" 2>&1 &
PIDS="$PIDS $!"
timeout 40 "$GODOT" --headless --path . -- --bot --idle --name=Cy --past=baker --start=2 --port=$PORT --seconds=14 >"$OUT/cy.log" 2>&1 &
PIDS="$PIDS $!"
for p in $PIDS; do wait $p; done
kill $SERVER 2>/dev/null
grep -HE "ERROR" "$OUT"/*.log | sed "s|$OUT/||"
cat "$OUT"/*.log | grep -E "^BOT|Server listening"
fail=0
grep -q "ERROR" "$OUT"/*.log && { echo "FAIL: errors in logs"; fail=1; }
for bot in ann bo; do
  grep -q "players_seen=3" "$OUT/$bot.log" || { echo "FAIL: $bot did not see the other players"; fail=1; }
  grep -q "party=2" "$OUT/$bot.log" || { echo "FAIL: $bot is not in a party of two"; fail=1; }
done
grep -q "companion=Vex" "$OUT/cy.log" || { echo "FAIL: cy did not recruit the companion"; fail=1; }
grep -q 'levels=\["The Intake"\]' "$OUT/cy.log" || { echo "FAIL: cy was not sent the level"; fail=1; }
[ $fail -eq 0 ] && echo "multiplayer smoke test passed"
exit $fail

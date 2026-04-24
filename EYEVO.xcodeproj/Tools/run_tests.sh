#!/usr/bin/env bash
set -euo pipefail

# Robust test runner for xcodebuild tests. Finds a booted simulator UDID if possible,
# falls back to booting a preferred simulator, then runs xcodebuild test with that UDID.

PREFERRED=("iPhone 17" "iPhone 17 Pro" "iPhone 16e" "iPhone 14")

# Try to get a Booted UDID via simctl JSON + python3 (if available)
UDID=""
SIMCTL_JSON=""
if command -v xcrun >/dev/null 2>&1; then
  SIMCTL_JSON=$(xcrun simctl list devices --json 2>/dev/null || true)
fi

if [ -n "$SIMCTL_JSON" ] && command -v python3 >/dev/null 2>&1; then
  UDID=$(printf "%s" "$SIMCTL_JSON" | python3 - <<'PY'
import sys, json
try:
    j=json.load(sys.stdin)
    for runtime, devices in j.get('devices', {}).items():
        for d in devices:
            if d.get('state')=='Booted':
                print(d.get('udid'))
                sys.exit(0)
except Exception:
    pass
print('')
PY
)
fi

# Fallback: try to parse human-readable simctl list
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl list devices | awk -F '[()]' '/Booted/ {print $2; exit}' || true)
fi

# If still empty, pick a preferred device and boot it
if [ -z "$UDID" ] || [ "$UDID" = "" ]; then
  echo "No booted simulator found; selecting a preferred device to boot..."
  for name in "${PREFERRED[@]}"; do
    LINE=$(xcrun simctl list devices | grep -m1 "$name (" || true)
    if [ -n "$LINE" ]; then
      # extract UDID from line
      UDID=$(echo "$LINE" | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/')
      if [ -n "$UDID" ]; then
        echo "Booting simulator $name -> $UDID"
        xcrun simctl boot "$UDID" || true
        sleep 2
        break
      fi
    fi
  done
fi

if [ -z "$UDID" ] || [ "$UDID" = "" ]; then
  echo "No suitable iOS simulator found. Run 'xcrun simctl list devices' to inspect available simulators."
  exit 2
fi

echo "Using simulator UDID: $UDID"

# Run tests via project so xcodebuild can find the scheme and test target
xcodebuild -project /Users/krishnamnimmala/Documents/Model/EYEVO/EYEVO.xcodeproj -scheme EYEVO -destination "id=$UDID" test

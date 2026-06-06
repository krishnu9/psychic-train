#!/usr/bin/env bash
# Audits screens/widgets for forbidden design system patterns.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGETS="$ROOT/lib/screens $ROOT/lib/widgets"
PATTERN='Color\(0x|Colors\.|ElevatedButton|OutlinedButton|FontWeight\.w[5-9]'

echo "Design system audit — scanning lib/screens and lib/widgets..."
echo ""

if command -v rg >/dev/null 2>&1; then
  MATCHES=$(rg "$PATTERN" $TARGETS --glob '!**/design_system/**' -n || true)
else
  MATCHES=$(grep -rnE "$PATTERN" $TARGETS 2>/dev/null || true)
fi

if [ -z "$MATCHES" ]; then
  echo "✓ No forbidden patterns found."
  exit 0
fi

echo "⚠ Forbidden patterns found (expected during migration):"
echo "$MATCHES"
echo ""
echo "See lib/design_system/FORBIDDEN_PATTERNS.md and MIGRATION.md."
echo "Count: $(echo "$MATCHES" | wc -l | tr -d ' ') lines"
exit 0

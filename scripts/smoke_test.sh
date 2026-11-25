#!/usr/bin/env bash
# Generates one clip with the released F5-TTS checkpoint to prove the setup works.
# Usage: conda activate subtext && bash scripts/smoke_test.sh
# With no arguments, f5-tts_infer-cli uses the example config that ships with
# F5-TTS (src/f5_tts/infer/examples/basic/basic.toml).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
F5_DIR="$ROOT/external/F5-TTS"

if ! command -v f5-tts_infer-cli >/dev/null 2>&1; then
  echo "f5-tts_infer-cli not found. Run scripts/setup_env.sh and activate the env." >&2
  exit 1
fi
if [ ! -d "$F5_DIR" ]; then
  echo "No F5-TTS checkout at $F5_DIR. Run scripts/setup_env.sh first." >&2
  exit 1
fi

cd "$F5_DIR"
f5-tts_infer-cli

echo
echo "Done. Audio saved to: $F5_DIR/tests/infer_cli_basic.wav"
echo "Listen to it, then note the result in LOG.md."
echo
echo "To try your own voice sample and text:"
echo '  f5-tts_infer-cli --model F5TTS_v1_Base \'
echo '    --ref_audio path/to/sample.wav \'
echo '    --ref_text "What is said in the sample." \'
echo '    --gen_text "The text you want spoken."'

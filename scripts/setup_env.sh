#!/usr/bin/env bash
# Sets up the conda env and an editable F5-TTS checkout in external/F5-TTS.
# Usage: bash scripts/setup_env.sh
# Optional: export F5_REPO=https://github.com/<you>/F5-TTS.git  (your fork)
set -euo pipefail

ENV_NAME="${ENV_NAME:-subtext}"
F5_REPO="${F5_REPO:-https://github.com/SWivid/F5-TTS.git}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found. Install Miniconda first." >&2
  exit 1
fi

eval "$(conda shell.bash hook)"

if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" python=3.11
fi
conda activate "$ENV_NAME"
conda install -y ffmpeg

# PyTorch build for NVIDIA GPUs, as given in the F5-TTS README.
# Change this line if your CUDA version or hardware differs.
pip install torch==2.8.0+cu128 torchaudio==2.8.0+cu128 \
  --extra-index-url https://download.pytorch.org/whl/cu128

mkdir -p "$ROOT/external"
if [ ! -d "$ROOT/external/F5-TTS/.git" ]; then
  git clone "$F5_REPO" "$ROOT/external/F5-TTS"
fi
pip install -e "$ROOT/external/F5-TTS"

python - <<'PY'
import torch
print("torch", torch.__version__, "| cuda available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("gpu:", torch.cuda.get_device_name(0))
PY

echo
echo "Setup finished. Next: conda activate $ENV_NAME && bash scripts/smoke_test.sh"

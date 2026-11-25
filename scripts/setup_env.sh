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

# PyTorch build: picked from the hardware.
# - NVIDIA GPU (Linux): the CUDA build given in the F5-TTS README. Override
#   with TORCH_CUDA=cu126 (etc.) if the driver is too old for CUDA 12.8.
# - Mac or no NVIDIA GPU: the default build (Apple GPU "MPS" on a Mac, else CPU).
TORCH_VERSION="${TORCH_VERSION:-2.8.0}"
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  TORCH_CUDA="${TORCH_CUDA:-cu128}"
  echo "NVIDIA GPU found: installing torch $TORCH_VERSION+$TORCH_CUDA"
  pip install "torch==$TORCH_VERSION+$TORCH_CUDA" "torchaudio==$TORCH_VERSION+$TORCH_CUDA" \
    --extra-index-url "https://download.pytorch.org/whl/$TORCH_CUDA"
else
  echo "No NVIDIA GPU found: installing default torch $TORCH_VERSION build"
  pip install "torch==$TORCH_VERSION" "torchaudio==$TORCH_VERSION"
fi

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
elif torch.backends.mps.is_available():
    print("gpu: Apple MPS (fine for the smoke test, too slow for the full evaluation)")
PY

echo
echo "Setup finished. Next: conda activate $ENV_NAME && bash scripts/smoke_test.sh"

#!/usr/bin/env bash
# Reproduces the F5-TTS LibriSpeech-PC test-clean numbers (word error rate and
# SIM-o) with the released F5TTS_v1_Base checkpoint.
#
# Needs an NVIDIA GPU: the F5-TTS evaluation code is hard-wired to CUDA.
# Run scripts/setup_env.sh first, then:
#   conda activate subtext
#   bash scripts/run_eval.sh subset   # fixed 200-utterance subset (pipeline check)
#   bash scripts/run_eval.sh full     # all 1127 utterances
#
# Downloads on first run (all land in git-ignored folders or the HF/torch cache):
#   LibriSpeech test-clean      ~0.35 GB  -> external/F5-TTS/data/LibriSpeech
#   WavLM speaker model         ~1.3 GB   -> external/checkpoints/UniSpeech
#   WavLM-large backbone        ~1.3 GB   -> torch hub cache (via s3prl)
#   faster-whisper-large-v3     ~3.1 GB   -> Hugging Face cache
#   F5TTS_v1_Base + vocoder     ~1.4 GB   -> Hugging Face cache
set -euo pipefail

MODE="${1:-subset}"
SUBSET_N="${SUBSET_N:-200}"
SEED="${SEED:-0}"
GPUS="${GPUS:-[0]}"
MODEL_NAME="F5TTS_v1_Base"
CKPTSTEP=1250000

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
F5_DIR="$ROOT/external/F5-TTS"
LS_PATH="data/LibriSpeech/test-clean"
LIST="data/librispeech_pc_test_clean_cross_sentence.lst"
WAVLM_DIR="$ROOT/external/checkpoints/UniSpeech"
# Google Drive file id from the F5-TTS evaluation guide.
WAVLM_GDRIVE_ID="1-aE1NfzpRCLxA4GUxX9ITI3F9LlbtEGP"

case "$MODE" in subset|full) ;; *) echo "Usage: $0 [subset|full]" >&2; exit 1 ;; esac
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "No NVIDIA GPU found. The F5-TTS evaluation code only runs on CUDA." >&2
  exit 1
fi

cd "$F5_DIR"
export PYTHONWARNINGS="ignore::UserWarning,ignore::FutureWarning"

# 1. Scoring tools. ctranslate2 4.5.0 is the build the guide names for
#    CUDA 12 + cuDNN 9, which is what the torch cu128 wheels ship.
#    Not `pip install -e .[eval]`: faster_whisper 0.10.1 pins av==10, which
#    has no ready-made build for Python 3.11 and fails to compile. Installing
#    it without its pins and adding current versions of what it needs works.
#    (funasr/modelscope are skipped: only the Chinese test set uses them.)
pip install -q --no-deps faster_whisper==0.10.1
pip install -q av ctranslate2==4.5.0 onnxruntime jiwer zhon zhconv gdown

# 2. Test set.
if [ ! -d "$LS_PATH" ]; then
  mkdir -p data
  wget -q --show-progress -O data/test-clean.tar.gz https://www.openslr.org/resources/12/test-clean.tar.gz
  tar -xzf data/test-clean.tar.gz -C data
  rm data/test-clean.tar.gz
fi

# 3. Speaker-similarity model.
if [ ! -f "$WAVLM_DIR/wavlm_large_finetune.pth" ]; then
  mkdir -p "$WAVLM_DIR"
  gdown "$WAVLM_GDRIVE_ID" -O "$WAVLM_DIR/wavlm_large_finetune.pth"
fi

# 3b. The eval code wants the model at ckpts/<name>/model_<step>.safetensors,
#     not in the Hugging Face cache where the smoke test puts it. Link it.
CKPT_FILE="ckpts/$MODEL_NAME/model_$CKPTSTEP.safetensors"
if [ ! -e "$CKPT_FILE" ]; then
  mkdir -p "ckpts/$MODEL_NAME"
  CACHED="$(python -c "from huggingface_hub import hf_hub_download as d; print(d('SWivid/F5-TTS', '$MODEL_NAME/model_$CKPTSTEP.safetensors'))")"
  ln -s "$CACHED" "$CKPT_FILE"
fi

# 4. Pick the utterance list. The eval code reads a fixed path, so for the
#    subset we swap the list file in place and always restore it on exit.
git checkout -- "$LIST"
if [ "$MODE" = subset ]; then
  cp "$LIST" "$LIST.full"
  trap 'mv -f "$F5_DIR/$LIST.full" "$F5_DIR/$LIST"' EXIT
  python - "$LIST.full" "$LIST" "$SUBSET_N" <<'PY'
import random, sys
src, dst, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
lines = open(src).read().splitlines()
keep = sorted(random.Random(0).sample(range(len(lines)), n))  # fixed subset
open(dst, "w").write("\n".join(lines[i] for i in keep) + "\n")
print(f"subset: {n} of {len(lines)} utterances (random seed 0)")
PY
fi

# 5. Generate, then score. Settings are the script defaults, which match the
#    paper: 32 steps, Euler, sway sampling -1, CFG 2.0.
GEN_DIR="results/${MODEL_NAME}_${CKPTSTEP}/ls_pc_test_clean/seed${SEED}_euler_nfe32_vocos_ss-1_cfg2.0_speed1.0"
#    A leftover folder with every clip in it means generation finished but
#    scoring failed last time: reuse it instead of generating again.
N_WANT="$(wc -l < "$LIST")"
N_HAVE=0
if [ -d "$GEN_DIR" ]; then N_HAVE="$(find "$GEN_DIR" -name '*.wav' | wc -l)"; fi
if [ "$N_HAVE" -ne "$N_WANT" ]; then
  rm -rf "$GEN_DIR"
  accelerate launch src/f5_tts/eval/eval_infer_batch.py \
    -s "$SEED" -n "$MODEL_NAME" -t ls_pc_test_clean -c "$CKPTSTEP" -p "$LS_PATH"
fi

#    The speech recogniser (ctranslate2) needs the cuDNN/cuBLAS libraries that
#    pip installed alongside torch, but does not look there by itself.
NVIDIA_LIBS="$(python -c "import nvidia.cudnn, nvidia.cublas, os; print(os.path.join(list(nvidia.cudnn.__path__)[0], 'lib') + ':' + os.path.join(list(nvidia.cublas.__path__)[0], 'lib'))")"
export LD_LIBRARY_PATH="$NVIDIA_LIBS:${LD_LIBRARY_PATH:-}"

python src/f5_tts/eval/eval_librispeech_test_clean.py -e wer -g "$GEN_DIR" -n "$GPUS" -p "$LS_PATH" | tee "$GEN_DIR/_wer_summary.txt"
python src/f5_tts/eval/eval_librispeech_test_clean.py -e sim -g "$GEN_DIR" -n "$GPUS" -p "$LS_PATH" | tee "$GEN_DIR/_sim_summary.txt"

# 6. Keep subset and full results apart.
FINAL_DIR="${GEN_DIR}_${MODE}"
rm -rf "$FINAL_DIR"
mv "$GEN_DIR" "$FINAL_DIR"

echo
echo "Mode: $MODE | seed: $SEED | results in $F5_DIR/$FINAL_DIR"
echo "Targets: WER 2.42% / SIM-o 0.66 (paper) or about 2.0% / 0.68 (v1 checkpoint)."

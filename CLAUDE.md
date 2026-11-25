# subtext: project context for Claude Code

Read this first. Then read `LOG.md` (latest entry) and `docs/stage3.md`.

## What this project is

A research project aiming at a 4-page speech paper. Sole researcher: Stephen
(first research project; EE background, comfortable with code and ML basics).

**Research question:** can a two-speed code, learned only by rebuilding real
conversation from plain transcripts, capture both the overall feel of speech
and its small sounds (breaths, laughs, hesitations), and can a predictor then
choose both from the script alone?

Hard rule of the idea: no labels, no audio tags, no style prompts. The model is
never told where a non-verbal sound goes.

## Design

- Base model: F5-TTS (flow matching, text-guided speech infilling), fine-tuned,
  not trained from scratch. It lives in `external/F5-TTS` (a separate fork,
  not in this repo).
- Slow code: one per phrase. Overall feel (tone, rhythm, mood).
- Fast code: several per second. Breaths, laughs, hesitations.
- Predictor: picks both codes from the script (and conversation history).
- Lessons from earlier work (details in `notes/papers.md`):
  - keep codes small (2 to 32 numbers);
  - let the code-maker see the script and the voice sample, or the code soaks
    up words and speaker identity;
  - never sample fast codes independently: snap to a fixed set and predict
    them in sequence;
  - likely insertion points in F5-TTS: fast code alongside the audio/text
    inputs frame by frame, slow code through the step-signal conditioning.
    Plausible, untested.

## What is and isn't new

The two-speed code already exists (Hono et al. 2020, HiMuV-TTS 2022) on older
models and read speech. Do not present it as the novelty. The contribution is:

1. that design on a modern flow-matching model,
2. trained on real conversation,
3. scored on whether sounds land in sensible places.

Point 3 is the strongest piece. No paper found checks placement of individual
breaths or laughs.

## Data

See `docs/data.md`. Key points:

- Main training data: Open Yap 1K (access by request).
- Its transcripts mark fillers, laughs, coughs and noise separately. Those
  marks are a hidden answer key for scoring. **Never feed them to the model.**
- Audio never goes in git. Open Yap forbids redistribution and identifiable
  voice clones.
- F5-TTS released weights are CC-BY-NC: research use only.

## Plan and current stage

Six stages: question, reading, baseline, tiny experiment, scale up, write.
Stages 1 and 2 are done. **Stage 3 (baseline) is current**: see
`docs/stage3.md`. The README status table is the source of truth; update it
when a stage changes.

12-week build order after the baseline: slow code (does swapping it change the
feel?), then fast code (do laughs and fillers land where real ones did?), then
the predictor and a listening test against plain F5-TTS.

Target venue: Speech Synthesis Workshop (SSW14), deadline 20 April 2027.
Interspeech 2027 (reported deadline 9 February 2027, unconfirmed) is a stretch.

## How to work in this repo

- Add a dated entry to `LOG.md` for every session that runs something: what
  ran, what happened, what it might mean, what's next.
- Change one thing at a time between runs.
- Each stage ends at a gate. If a gate fails, fix it or shrink the question
  before moving on.
- Reproduce before trusting: no result from our own changes counts until the
  baseline number in `docs/stage3.md` is matched.
- Say plainly what was tested and what wasn't. Never report a script as
  working if it was only syntax-checked.
- Before claiming anything is "first" or "new", search for prior work again.
- Commit and push straight to main. No branches or pull requests.

## How to talk to Stephen

- Plain language, short answers. Define any technical term in one sentence.
- He is a visual learner: use a diagram when explaining how something works.
- He wants AI to do the routine work (searching, extracting, setup), with
  small spot-checks he can do himself.

## Known unknowns

- Whether Open Yap 1K marks breaths.
- `scripts/run_eval.sh` has been syntax-checked only, never run. It needs an
  NVIDIA GPU (the F5-TTS evaluation code is hard-wired to CUDA), so it runs on
  a rented vast.ai machine, not the Mac.

Answered (2026-11-25):

- No pretrained Small (158M) F5-TTS checkpoint is published. The Hugging Face
  repo `SWivid/F5-TTS` holds only Base models (`F5TTS_Base`,
  `F5TTS_Base_bigvgan`, `F5TTS_v1_Base`, `F5TTS_v1_Base_no_zero_init`). Plan:
  fine-tune Base with most layers frozen.
- `scripts/setup_env.sh` and `scripts/smoke_test.sh` run on the Mac (Apple M4
  Pro, MPS). Neither has been run on an NVIDIA machine yet.
- Evaluation commands: wrapped in `scripts/run_eval.sh`.

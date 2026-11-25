# subtext

Everything in speech that the script doesn't say.

## Research question

Can a two-speed code, learned only by rebuilding real conversation from plain
transcripts, capture both the overall feel of speech and its small sounds
(breaths, laughs, hesitations), and can a predictor then choose both from the
script alone?

No labels. No audio tags. Nobody tells the model where a sigh goes.

## What gets built

- **Slow code** (one per phrase): tone, rhythm, mood.
- **Fast code** (several per second): breaths, laughs, hesitations.
- **Predictor**: reads only the script and picks both codes.
- All three are added to [F5-TTS](https://github.com/SWivid/F5-TTS).

The two-speed code itself is not new (see `notes/papers.md`). The contribution
is the combination on a modern model with conversational data, plus a way to
score whether sounds land in sensible places.

## Status

| Stage | State |
| --- | --- |
| 1. Pick one question | Done |
| 2. Read the papers | Done (AI-extracted notes, spot-checked) |
| 3. Rerun a baseline | **In progress** - see `docs/stage3.md` |
| 4. Tiny experiment | Not started |
| 5. Scale it up | Not started |
| 6. Write and share | Not started |

## Layout

```
LOG.md            research log, one dated entry per session
docs/stage3.md    checklist for getting the baseline running
docs/data.md      datasets, access and licence rules
notes/papers.md   notes on the ten core papers
scripts/          setup, smoke-test and evaluation scripts
src/subtext/      project code (empty until stage 4)
external/         F5-TTS checkout (not in git)
data/             audio (not in git)
```

## Quick start

On a machine with an NVIDIA GPU and conda:

```bash
bash scripts/setup_env.sh     # creates the env, installs F5-TTS
conda activate subtext
bash scripts/smoke_test.sh    # generates one clip to prove the setup works
```

## Licences to keep in mind

- F5-TTS code is MIT. Its released weights are CC-BY-NC (research use only).
- Open Yap 1K forbids redistribution and identifiable voice clones.

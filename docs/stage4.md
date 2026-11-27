# Stage 4: tiny experiment

Not started. This page lists what is ready, what is still open, and a proposed
first run. The proposal is Claude's; Stephen has not signed it off.

## The picture

```
 Mac (AWS keys)            rented GPU (vast.ai, rented per session)
┌─────────────────┐       ┌──────────────────────────────────────────┐
│ fetch_open_yap  │ links │ setup_env.sh        F5-TTS + PyTorch      │
│   links         ├──────►│ fetch_open_yap      download + unpack     │
└─────────────────┘       │   download          (about 1 hour)        │
                          │ prep_open_yap.py    cut into clips,       │
                          │                     fillers out of text   │
                          │ F5-TTS prepare_csv_wavs.py + fine-tune    │
                          │ run_eval.sh         same scoring as       │
                          │                     the baseline          │
                          └───────────────┬──────────────────────────┘
                                          │ results, checkpoints
                                          ▼ copy back, then destroy machine
```

Decision (2026-11-27): no kept disk. The data is downloaded again each
session, because disk rent on vast.ai (about $30-50 a month for 150 GB) costs
far more than the hour a download takes.

## Ready

| Piece | State |
| --- | --- |
| Baseline number | Reproduced (stage 3). |
| F5-TTS fork | `stephenqiao1/F5-TTS`, pinned at commit 600e5fd. |
| `scripts/fetch_open_yap.sh` | Tested on the Mac: links made, smallest part downloaded with no AWS keys, checked and unpacked. Not yet run on a rented machine or on all 79 parts. |
| `scripts/prep_open_yap.py` | Tested on the Mac on 2 conversations: 764 clips, 1.8 hours. F5-TTS's `prepare_csv_wavs.py` accepted the output. Not yet run on the full set. |
| Fine-tuning | Not tried at all. |

## Open, in order of urgency

1. **The delivery is deleted on 26 December 2026.** After that date nothing
   can be re-downloaded. Before then, either keep a private copy somewhere
   (allowed: it is storage, not redistribution, but read the Data Use
   Agreement first) or confirm with the provider that a new delivery can be
   requested later.
2. **Only fillers are marked.** In the one part inspected (21 of 1,602
   conversations, 161,256 timed tokens) every token is `word` or `filler`.
   No laugh, cough, noise or breath marks, although the dataset page says
   laughs and coughs are tagged. Check all parts on the first full download.
   If it holds, placement scoring can use fillers directly, and laughs and
   breaths need our own detector or have to leave the question.
3. **Fillers are written in the plain transcript** ("uh," "um," "Mhmm.").
   Training on the transcript as delivered would tell the model where they
   go. `prep_open_yap.py` therefore removes them from the text and keeps
   their positions in `answer_key.jsonl`, for scoring only.

## Proposed first runs (one change at a time)

- [ ] 0. Full download on a rented machine. Count token types over all parts
      (settles open point 2). Run `prep_open_yap.py --no-audio` for totals.
- [ ] 1. Control: fine-tune plain F5-TTS on a small slice (about 10 hours of
      clips), nothing added. Check the baseline score has not collapsed and
      listen: does it start producing fillers by itself?
- [ ] 2. Add the slow code (one per clip) and fine-tune on the same slice.
- [ ] 3. Gate: same text and voice sample, swap the slow code. Does the feel
      change? If yes, go to the fast code. If no, fix or shrink the question.

## Rules that apply here

- Audio, clips, links files and checkpoints stay out of git (`data/`,
  `external/` and `ckpts/` are ignored).
- Never feed `answer_key.jsonl` or filler tokens to a model.
- No voice clones identifiable as an Open Yap speaker in anything shared.
- Rent, test download speed, run, copy results back, destroy the machine.

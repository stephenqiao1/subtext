# Research log

One entry per working session. Change one thing at a time.

Template:

```
## YYYY-MM-DD
Ran:
Result:
Think:
Next:
```

---

## 2026-11-24
Ran: literature review; Undermind deep search (141 papers ranked) for "has this
been done"; full-PDF extraction on the ten core papers.
Result: full combination not found. The two-speed code already exists
(Hono 2020, HiMuV-TTS 2022) on older models and read speech. No paper checks
whether a single breath or laugh lands at a sensible moment.
Think: contribution = known design + modern flow-matching model +
conversational data + placement scoring. The scoring is the strongest piece.
Spot-checked three numbers by hand (Capacitron Table B.2, NonverbalTTS Table 8,
dGSLM Table 3): all matched.
Next: stage 3. Request Open Yap 1K access, get F5-TTS generating audio,
reproduce one number from the F5-TTS paper.

## 2026-11-25
Ran: on the Mac (Apple M4 Pro, 24 GB, no NVIDIA GPU, conda 25.5.1):
`scripts/setup_env.sh` and `scripts/smoke_test.sh`, F5-TTS at commit 600e5fd.
Read (not ran) the F5-TTS evaluation guide and code. Listed the files in the
Hugging Face repo `SWivid/F5-TTS`.
Result: setup works after one fix (the script now picks the PyTorch build from
the hardware: CUDA build on NVIDIA, default build on a Mac). Smoke test made a
15 s clip with F5TTS_v1_Base at `external/F5-TTS/tests/infer_cli_basic.wav`;
not listened to yet. No Small (158M) checkpoint is published, only Base
models. No word error rate or SIM-o number yet: the evaluation code is
hard-wired to CUDA, so it cannot run on the Mac.
Think: the baseline number needs a rented GPU (vast.ai). Wrote
`scripts/run_eval.sh` for that; it is syntax-checked only. The CUDA branch of
`setup_env.sh` is also untested. Stage 3 is not passed.
Next: set up vast.ai (account, API key, budget), rent one 24 GB GPU, run
setup, smoke test, then `run_eval.sh subset` and, if sane, `full`. Listen to
the clip. Send the Open Yap 1K access request.

## 2026-11-25 (later): baseline reproduced
Ran: on a rented vast.ai RTX 3090 (24 GB, CUDA 12.8 build of PyTorch 2.8.0):
`setup_env.sh`, `smoke_test.sh`, then `run_eval.sh subset` and
`run_eval.sh full`. LibriSpeech-PC test-clean, `F5TTS_v1_Base`, 32 steps,
seed 0, F5-TTS commit 600e5fd.
Result:
- fixed subset of 200 utterances: word error rate 2.26%, SIM-o 0.675;
- full test set, 1127 utterances: word error rate 2.13%, SIM-o 0.674.
Targets: 2.42% / 0.66 (paper) and about 2.0% / 0.68 (newer checkpoint).
Generating the full set took 19 minutes. Total vast.ai cost about $0.75.
Problems fixed in `run_eval.sh` along the way: the speech recogniser's pinned
audio library would not build (installed without its pins); the eval code
wants the model file under `ckpts/` (linked from the download cache); the
recogniser could not find the GPU library cuDNN (path added). The first
rented machine could not download from Hugging Face and was replaced.
Think: the setup is right. Both numbers sit between the two target pairs.
One seed only (the F5-TTS repo script uses three), so the last digit can
wobble. The scoring pipeline (recogniser plus speaker model) now works and
can be reused for our own models.
Not done: nobody has listened to the smoke-test clip yet; F5-TTS is still
the upstream repo, not a fork; Open Yap 1K access is granted but the data
(148 GiB) is not downloaded because the Mac has only about 90 GiB free.
Next: Stephen listens to the clip. Fork F5-TTS. Decide where Open Yap lives.
Then stage 4.

## 2026-11-27
Ran: forked SWivid/F5-TTS to stephenqiao1/F5-TTS. Pointed `external/F5-TTS`
at the fork (`origin` = fork, `upstream` = SWivid) and made `setup_env.sh`
clone the fork by default. Nothing was re-run.
Result: fork exists. The local checkout stays at 600e5fd, the commit the
baseline was reproduced on; the fork's main is 7 commits ahead of that.
Think: stay on 600e5fd for now. If we move to newer upstream code, rerun
`run_eval.sh` first so the baseline still holds.
Next: Stephen listens to the clip. Decide where Open Yap lives. Then stage 4.

## 2026-11-27 (later): getting ready for stage 4
Ran: on the Mac only. Downloaded the Open Yap index files and one part of 79
(2 GiB, 21 conversations), checksums OK, and inspected it. Wrote and tested
`scripts/fetch_open_yap.sh` (download with temporary links, no AWS keys on
the rented machine) and `scripts/prep_open_yap.py` (cut conversations into
clips, fillers removed from the text). Ran F5-TTS's `prepare_csv_wavs.py` on
the clips from 2 conversations.
Result:
- delivery: 1,602 conversations, 1,000.2 h, 148 GiB; the provider deletes it
  on 26 December 2026;
- token types in the part inspected: 159,851 `word`, 1,405 `filler`, nothing
  else. No laugh, cough, noise or breath marks;
- fillers appear in the plain transcript text;
- clip cutting on 21 conversations: 5,788 clips, 12.7 h kept out of 31.9 h
  of track time (mean 7.9 s); most dropped pieces are under 3 s;
- F5-TTS data preparation accepted 764 clips (1.81 h).
Think: the answer key is thinner than the dataset page suggests. If the other
parts match, placement scoring works for fillers out of the box, and laughs
and breaths need our own detector or leave the question. This touches the
paper's strongest claim, so settle it early. One part is 1.3% of the data,
so do not conclude yet. Dropping pieces under 3 s also drops most short
replies ("Yeah.", "Mhmm."); fine for a first run, revisit later.
Decided: no kept disk on vast.ai; download again each session.
Not tested: either new script on a rented machine or on the full set;
fine-tuning.
Next: decide what to do about the 26 December deletion. Then stage 4 step 0
in `docs/stage4.md`: full download, count token types over all parts.

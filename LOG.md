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

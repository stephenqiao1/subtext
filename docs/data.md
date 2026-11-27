# Data

Audio never goes in this repo. Everything below lives under `data/`, which is
gitignored.

| Dataset | Use | Size | Access | Rules |
| --- | --- | --- | --- | --- |
| [Open Yap 1K](https://huggingface.co/datasets/TheAgenticDataCompany/open-yap-1k) | Main training data | 1,000 h, two-person English conversation, 48 kHz, one speaker per track | By request (form on the dataset page) | No redistribution, no identifiable voice clones, no speaker identification |
| Open Yap 1K sample | First experiments | 8.92 h, 16 conversations | On the Hugging Face Hub, CC-BY-4.0 | Hand-picked, not representative |
| [15-hour full-duplex set](https://arxiv.org/abs/2509.04093) | Held-out test set | 15 h, Chinese and English | Open, CC BY 4.0 | Keep out of training |
| LibriSpeech-PC test-clean | Baseline check only | - | See the F5-TTS eval guide | - |

## Things to know about Open Yap 1K

- Transcripts are machine-made (Deepgram Nova-3) and not human-checked.
- Fillers, laughs, coughs and noise are marked separately from words. These
  marks are **never shown to the model**. They are the hidden answer key for
  scoring where sounds land.
- The dataset page does not say breaths are marked. Checked 2026-11-27 on
  one part (21 conversations): only `word` and `filler` tokens exist. No
  breath, laugh, cough or noise marks. Not yet checked on the other 78 parts.
- Fillers ("uh," "um," "Mhmm.") also appear in the plain transcript text, so
  they must be stripped before training (`scripts/prep_open_yap.py` does it).

## What the full delivery looks like (received 2026-11-25)

- 79 tar files, 148 GiB, on Amazon S3. **Deleted by the provider on
  26 December 2026.** Not downloaded in full; see `docs/stage4.md`.
- 1,602 conversations, 1,000.2 hours, English, 48 kHz FLAC, one file per
  speaker.
- Per conversation: `meta.json` (relationship, topics, speaker ids),
  per-speaker `*_meta.json` (age range, gender, country, audio quality),
  `*_transcript.json` (plain `text` plus `words`, each with `start`, `end`
  and `type`), and two audio-quality time series.
- Redacted details appear as tokens like `[PHONE_NUMBER_1]`.
- On the Mac: one part (2 GiB, 21 conversations) in `data/open-yap-1k/sample/`
  and the index files in `data/open-yap-1k/meta/`.

## To do

- [x] Send the Open Yap 1K access request. Granted 2026-11-25.
- [ ] Read its Data Use Agreement before publishing any audio samples.
- [ ] Download the Hub sample to `data/open-yap-sample/`.

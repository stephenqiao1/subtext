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
- The dataset page does not say breaths are marked. Check once access arrives.

## To do

- [ ] Send the Open Yap 1K access request.
- [ ] Read its Data Use Agreement before publishing any audio samples.
- [ ] Download the Hub sample to `data/open-yap-sample/`.

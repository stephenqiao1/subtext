# Notes on the ten core papers

Extracted by Undermind from the full PDFs on 2026-11-24. Three numbers were
checked by hand against the papers and matched (Capacitron Table B.2,
NonverbalTTS Table 8, dGSLM Table 3).

Headline: none of the ten tests whether a single breath or laugh lands at a
sensible moment, and none of the learned-code papers was trained on speech
that contains those sounds.

| Paper | What they showed | Data | What they left out |
| --- | --- | --- | --- |
| [dGSLM](https://arxiv.org/abs/2203.16502) | No text or labels; laughter 3.62/min vs 3.60 real. Naturalness 3.70/5, meaning 2.48 (real 4.21). | ~2,000 h two-channel phone calls (Fisher) | Only average rates; no per-laugh fit check; no pitch modelling; not script-driven. |
| [Hono et al. 2020](https://arxiv.org/abs/2009.08474) | Codes at sentence, phrase and word level (2 numbers each), each picked from text and the level above. Best expressiveness 3.37/5. | 10 h, one Japanese speaker, acted styles | No breaths, laughs or conversation; one speaker; naturalness slightly below a one-level model. |
| [HiMuV-TTS](https://arxiv.org/abs/2204.04004) | Slow code (32 numbers, whole sentence) + fast code (16 per sound). Slow changes speed; fast changes short pauses. 3.97/5, equal to baseline, more variety. | 24 h, one audiobook reader (LJ Speech) | No breaths, laughs or conversation; no leakage analysis. |
| [Mitsui et al. 2022](https://arxiv.org/abs/2206.12040) | Slow code (16 numbers) learned from real dialogue, predicted from the last 10 turns. Dialogue naturalness 3.34 -> 3.53. | 18,385 turns, free Japanese conversation, two speakers | Slow code only; never checks laughs or fillers; needs past transcripts and timings. |
| [Capacitron](https://arxiv.org/abs/1906.03402) | Bigger code -> worse speech when the code is predicted: 4.44 -> 2.34. With text shown to the code-maker: only down to 3.81. | 36.5 h audiobook; 327 h, 58 speakers | No breaths, laughs or conversation; leakage shown indirectly. |
| [Sun et al. 2020](https://arxiv.org/abs/2002.03788) | Fast codes (3 numbers per sound) picked independently: 94.7% word errors. Fixed code set + sequence predictor: 3.98/5, 8.4% word errors. | 585 h audiobooks (LibriTTS) | No breaths, laughs or conversation; snapping costs accuracy. |
| [F5-TTS](https://arxiv.org/abs/2410.06885) | Script to speech, no timing model. 2.42% word errors, voice match 0.66. Base 336M, Small 158M. | ~95,000 h in-the-wild English and Chinese (Emilia) | Nothing on breaths, laughs or fillers; no fine control of emotion. |
| [SpeechFlow](https://arxiv.org/abs/2310.16338) | Rebuilding hidden audio with no labels improves voice match (0.700 vs 0.569 from scratch), not word accuracy. | 60,000 h unlabelled audiobooks | Audiobooks only; never measures which non-word details are learned. |
| [NonverbalTTS](https://arxiv.org/abs/2507.13155) | Tags help a little: breath score 0.92 with tags, 0.88 without. No significant listener preference vs CosyVoice2. | 17 h; 3,612 breaths, 1,018 laughs, 7 grunts | Scores presence, not placement; no label accuracy. |
| [Speech LLMs That Breathe](https://arxiv.org/abs/2610.25942) | A language model places sound tokens; its own judge rates placement 92.5% -> 96.8%. | Synthetic Mandarin dialogues; judge trained on real tagged speech | Judge only moderately accurate (0.76; 0.5 is chance); no human placement test; no tag-free comparison; breath down-weighted. |

## Design lessons

- Start with small codes (earlier work: 2 to 32 numbers).
- Let the code-maker see the script and the voice (Capacitron: voice match 78.0% -> 94.9%).
- Never pick fast codes independently. Snap to a fixed set and predict in sequence (Sun et al.). A fast code alone scored 2.83 vs 3.97 for slow + fast (HiMuV-TTS).
- Predict the slow code from conversation history (Mitsui et al.).
- In F5-TTS, the fast code can sit beside the audio and text inputs frame by frame; the slow code can go in where the model receives its step signal. Plausible from the paper, not tested there.
- Fine-tune, don't train from scratch.

## Measures to reuse

| What | Tool | Used by |
| --- | --- | --- |
| Word errors | Whisper-large-v3 | F5-TTS |
| Voice match | WavLM-based speaker model | F5-TTS |
| Predicted quality | UTMOS | F5-TTS |
| Laughs per minute | Open-source laughter detector | dGSLM |
| Fillers per 100 words | Count "uh", "um" etc. in a transcript | dGSLM |
| Pauses, gaps, overlaps | pyannote voice activity detection | dGSLM |
| Sound present or not | BEATs sound-event detector | NonverbalTTS |

## Still to read closely by hand

Hono et al., HiMuV-TTS, Capacitron, Sun et al., F5-TTS.

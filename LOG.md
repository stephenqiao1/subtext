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

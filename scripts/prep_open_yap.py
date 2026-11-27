#!/usr/bin/env python
"""Cuts Open Yap 1K conversations into short clips for F5-TTS fine-tuning.

Usage (inside the subtext conda env):
    python scripts/prep_open_yap.py --src data/open-yap-1k/sample --out data/open-yap-1k/prepared/sample
    python scripts/prep_open_yap.py --src ... --out ... --no-audio      # numbers only, writes no clips

--src is the folder that contains conversations/conv_*/ .

What it writes under --out:
    wavs/<conversation>_<a|b>_<number>.wav   24 kHz mono clips
    metadata.csv      "audio_file|text" - the format F5-TTS's prepare_csv_wavs.py reads
    segments.jsonl    one line per clip: conversation, speaker, start, end, text
    answer_key.jsonl  one line per clip: where each filler sits inside the clip

Project rule: the model is never told where a non-verbal sound goes. So filler
tokens ("uh", "um", "mhmm") are REMOVED from the text in metadata.csv and
segments.jsonl. The audio still contains them. answer_key.jsonl is the hidden
answer key for scoring only. Never feed it to a model.

How clips are cut: each speaker has a separate track with word timings. Words
are grouped into a clip until the speaker pauses for more than --gap seconds.
Clips longer than --max-sec are split at their longest internal pause. Clips
shorter than --min-sec, with fewer than --min-words real words, or containing
a redacted token like [PHONE_NUMBER_1] are dropped.
"""

import argparse
import csv
import json
from pathlib import Path


def load_tokens(path):
    words = json.load(open(path))["words"]
    return [w for w in words if w["end"] > w["start"]]


def split_on_gaps(tokens, gap):
    groups, cur = [], []
    for w in tokens:
        if cur and w["start"] - cur[-1]["end"] > gap:
            groups.append(cur)
            cur = []
        cur.append(w)
    if cur:
        groups.append(cur)
    return groups


def split_long(group, max_sec):
    """Split at the longest internal pause until every piece fits."""
    if group[-1]["end"] - group[0]["start"] <= max_sec or len(group) < 2:
        return [group]
    gaps = [group[i + 1]["start"] - group[i]["end"] for i in range(len(group) - 1)]
    # Ignore cut points too close to either edge, so pieces are not tiny.
    lo, hi = len(group) // 5, len(group) - 1 - len(group) // 5
    i = max(range(lo, max(hi, lo + 1)), key=lambda k: gaps[k])
    return split_long(group[: i + 1], max_sec) + split_long(group[i + 1 :], max_sec)


def clean_text(group):
    return " ".join(w["word"] for w in group if w["type"] == "word").strip()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--gap", type=float, default=0.6, help="pause (s) that ends a clip")
    ap.add_argument("--min-sec", type=float, default=3.0)
    ap.add_argument("--max-sec", type=float, default=20.0)
    ap.add_argument("--min-words", type=int, default=3)
    ap.add_argument("--pad", type=float, default=0.15, help="silence (s) kept around a clip")
    ap.add_argument("--sr", type=int, default=24000, help="output sample rate (F5-TTS uses 24 kHz)")
    ap.add_argument("--max-convs", type=int, default=None, help="only the first N conversations")
    ap.add_argument("--no-audio", action="store_true", help="write the lists but no wav files")
    args = ap.parse_args()

    src, out = Path(args.src), Path(args.out).resolve()
    convs = sorted(p for p in (src / "conversations").iterdir() if p.is_dir())
    if args.max_convs:
        convs = convs[: args.max_convs]
    if not convs:
        raise SystemExit(f"No conversations found under {src}/conversations")
    (out / "wavs").mkdir(parents=True, exist_ok=True)

    if not args.no_audio:
        import soundfile as sf
        import soxr

    n_clips = n_fillers = 0
    kept_sec = track_sec = 0.0
    dropped = {"too_short": 0, "few_words": 0, "redacted": 0}
    with open(out / "metadata.csv", "w", newline="") as f_meta, open(out / "segments.jsonl", "w") as f_seg, open(
        out / "answer_key.jsonl", "w"
    ) as f_key:
        meta = csv.writer(f_meta, delimiter="|", quoting=csv.QUOTE_NONE, escapechar="\\")
        meta.writerow(["audio_file", "text"])
        for conv in convs:
            info = json.load(open(conv / "meta.json"))
            for spk in ("a", "b"):
                tokens = load_tokens(conv / f"speaker_{spk}_transcript.json")
                flac = conv / f"speaker_{spk}.flac"
                track_sec += info["duration_seconds"]
                groups = [g for big in split_on_gaps(tokens, args.gap) for g in split_long(big, args.max_sec)]
                idx = 0
                for gi, g in enumerate(groups):
                    start, end = g[0]["start"], g[-1]["end"]
                    text = clean_text(g)
                    if end - start < args.min_sec:
                        dropped["too_short"] += 1
                        continue
                    if sum(w["type"] == "word" for w in g) < args.min_words:
                        dropped["few_words"] += 1
                        continue
                    if "[" in text:
                        dropped["redacted"] += 1
                        continue
                    # Pad, but never into the neighbouring clip's words.
                    prev_end = groups[gi - 1][-1]["end"] if gi else 0.0
                    next_start = groups[gi + 1][0]["start"] if gi + 1 < len(groups) else info["duration_seconds"]
                    c0 = max(start - args.pad, (prev_end + start) / 2, 0.0)
                    c1 = min(end + args.pad, (end + next_start) / 2)
                    name = f"{conv.name}_{spk}_{idx:04d}"
                    wav = out / "wavs" / f"{name}.wav"
                    idx += 1
                    if not args.no_audio:
                        sr = sf.info(flac).samplerate
                        audio, _ = sf.read(flac, start=int(c0 * sr), stop=int(c1 * sr), dtype="float32")
                        if sr != args.sr:
                            audio = soxr.resample(audio, sr, args.sr)
                        sf.write(wav, audio, args.sr, subtype="PCM_16")
                    meta.writerow([str(wav), text.replace("|", " ")])
                    f_seg.write(
                        json.dumps(
                            {
                                "clip": name,
                                "conversation": conv.name,
                                "track": spk,
                                "speaker_id": info[f"speaker_{spk}_id"],
                                "start": round(c0, 3),
                                "end": round(c1, 3),
                                "text": text,
                            }
                        )
                        + "\n"
                    )
                    fillers = [
                        {
                            "word": w["word"],
                            "type": w["type"],
                            "start": round(w["start"] - c0, 3),
                            "end": round(w["end"] - c0, 3),
                        }
                        for w in g
                        if w["type"] != "word"
                    ]
                    f_key.write(json.dumps({"clip": name, "duration": round(c1 - c0, 3), "events": fillers}) + "\n")
                    n_clips += 1
                    n_fillers += len(fillers)
                    kept_sec += c1 - c0

    print(f"conversations: {len(convs)}  (speaker tracks: {2 * len(convs)}, {track_sec / 3600:.1f} h of track time)")
    print(f"clips kept: {n_clips}  = {kept_sec / 3600:.2f} h, mean {kept_sec / max(n_clips, 1):.1f} s")
    print(f"dropped: {dropped}")
    print(f"fillers in kept clips (answer key only): {n_fillers}")
    print(f"audio written: {'no (--no-audio)' if args.no_audio else 'yes'}  ->  {out}")


if __name__ == "__main__":
    main()

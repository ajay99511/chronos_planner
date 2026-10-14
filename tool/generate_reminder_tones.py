#!/usr/bin/env python3
"""Generates the bundled reminder tones in android/app/src/main/res/raw/.

## Why these are generated rather than licensed
A reminder has to ring for about ten seconds and then stop, and on Android the
only way to control that duration is the length of the channel's sound file
(see docs/decisions/0013-reminder-tones.md). These are **placeholders**: plain
synthesised tones, committed so the feature is complete and testable end to
end, and so the first real sound is a file swap rather than a code change.

Replacing one: drop a ~10s mono file over the matching .wav (or change the
extension in `ReminderTone`), keep the file name, and bump the channel suffix
in `ReminderTone.channelSuffix` so Android picks the new sound up — a
notification channel's sound is immutable once created.

Run:  python tool/generate_reminder_tones.py
No third-party dependencies: `wave` and `math` ship with Python.
"""

from __future__ import annotations

import math
import os
import struct
import wave

# 16 kHz is well above what a chime needs (nothing here exceeds 2 kHz) and
# keeps each 10-second file near 320 KB rather than the ~880 KB a 44.1 kHz
# stereo file would add to the APK, three times over.
SAMPLE_RATE = 16000
DURATION_SECONDS = 10.0
AMPLITUDE = 0.62

OUT_DIR = os.path.join("android", "app", "src", "main", "res", "raw")


def _envelope(t: float, attack: float, decay: float) -> float:
    """A struck-note envelope: fast attack, exponential decay."""
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def _write(name: str, samples: list[float]) -> str:
    path = os.path.join(OUT_DIR, f"{name}.wav")
    peak = max(abs(s) for s in samples) or 1.0
    frames = bytearray()
    for sample in samples:
        # Normalise, then scale to signed 16-bit.
        value = int(max(-1.0, min(1.0, sample / peak * AMPLITUDE)) * 32767)
        frames += struct.pack("<h", value)
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(bytes(frames))
    return path


def _render(voice, repeat_every: float) -> list[float]:
    """Repeats `voice(t_within_note)` every `repeat_every` seconds."""
    total = int(SAMPLE_RATE * DURATION_SECONDS)
    samples = [0.0] * total
    stride = int(SAMPLE_RATE * repeat_every)
    for start in range(0, total, stride):
        for i in range(min(stride, total - start)):
            samples[start + i] += voice(i / SAMPLE_RATE)
    return samples


def chime(t: float) -> float:
    """Warm two-note bell. The default: present without being an alarm."""
    env = _envelope(t, 0.005, 0.45)
    # A fifth apart, plus a quiet octave for shimmer.
    return env * (
        math.sin(2 * math.pi * 587.33 * t)
        + 0.55 * math.sin(2 * math.pi * 880.0 * t)
        + 0.18 * math.sin(2 * math.pi * 1174.66 * t)
    )


def pulse(t: float) -> float:
    """Three soft beeps, for someone who wants a plainer cue."""
    env = _envelope(t, 0.008, 0.08)
    return env * math.sin(2 * math.pi * 784.0 * t)


def marimba(t: float) -> float:
    """Plucky and short, the least intrusive of the three."""
    env = _envelope(t, 0.003, 0.22)
    return env * (
        math.sin(2 * math.pi * 523.25 * t)
        + 0.35 * math.sin(2 * math.pi * 1046.5 * t)
        + 0.12 * math.sin(2 * math.pi * 1568.0 * t)
    )


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    written = [
        _write("reminder_chime", _render(chime, 1.25)),
        _write("reminder_pulse", _render(pulse, 0.42)),
        _write("reminder_marimba", _render(marimba, 0.8)),
    ]
    for path in written:
        size = os.path.getsize(path)
        print(f"{path}  {size / 1024:.0f} KB")


if __name__ == "__main__":
    main()

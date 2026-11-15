#!/usr/bin/env python3
"""Generates the app's two short original sound effects (44.1 kHz, mono, 16-bit WAV).

Usage: python3 tools/make_sounds.py
Output: App/Resources/Sounds/tick.wav, App/Resources/Sounds/win.wav
"""
import math
import os
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "Resources", "Sounds")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        w.writeframes(frames)
    print("wrote", os.path.normpath(path), len(samples), "samples")


def tick():
    n = int(RATE * 0.040)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.002)
        env = attack * math.exp(-t * 110.0)
        s = math.sin(2 * math.pi * 1900 * t) + 0.3 * math.sin(2 * math.pi * 3800 * t)
        out.append(0.35 * env * s)
    # Short linear fade to avoid a click at the very end.
    fade = int(RATE * 0.004)
    for i in range(fade):
        out[n - 1 - i] *= i / fade
    return out


def win():
    total = int(RATE * 0.600)
    out = [0.0] * total
    # Rising C major arpeggio: C5 E5 G5 C6, notes overlap slightly.
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = 0.100
    for k, f in enumerate(notes):
        start = int(RATE * step * k)
        length = int(RATE * 0.38) if k < len(notes) - 1 else total - start
        for i in range(length):
            j = start + i
            if j >= total:
                break
            t = i / RATE
            attack = min(1.0, t / 0.006)
            env = attack * math.exp(-t * (7.0 if k < len(notes) - 1 else 4.5))
            s = math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * 2 * f * t)
            out[j] += 0.22 * env * s
    # Overall fade-out over the last 150 ms.
    fade = int(RATE * 0.150)
    for i in range(fade):
        out[total - 1 - i] *= i / fade
    return out


if __name__ == "__main__":
    write_wav("tick.wav", tick())
    write_wav("win.wav", win())

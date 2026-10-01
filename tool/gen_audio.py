"""Synthesizes the game's original sound effects and music loop (no third-party assets)."""
import numpy as np, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
rng = np.random.default_rng(7)

def save(name, x, vol=0.8):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * vol, -1, 1)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype('<i2').tobytes())

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=0.1):
    e = np.ones(n); na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na); e[-nr:] *= np.linspace(1, 0, nr); return e
def tone(f, d, a=0.005, r=0.1, harm=(1, .3, .1)):
    tt = t(d); x = sum(h * np.sin(2 * np.pi * f * (i + 1) * tt) for i, h in enumerate(harm))
    return x * env(len(tt), a, r)

# click
save('click.wav', tone(880, .06, .001, .05) + tone(1320, .06, .001, .05) * .4, .5)
# pop (brick removed / bubble)
tt = t(.12); f = 300 + 900 * np.exp(-tt * 30)
save('pop.wav', np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 28), .7)
# coin
save('coin.wav', np.concatenate([tone(1319, .07, .001, .03, (1, .2)), tone(1976, .25, .001, .22, (1, .2))]), .55)
# star
save('star.wav', np.concatenate([tone(f, .09, .002, .06, (1, .4, .2)) for f in (784, 988, 1175)]) , .6)
# win jingle
notes = [523, 659, 784, 1047]
x = np.concatenate([tone(f, .13, .003, .08, (1, .5, .25)) for f in notes[:-1]] + [tone(1047, .45, .003, .4, (1, .5, .25))])
save('win.wav', x, .7)
# fail
x = np.concatenate([tone(f, .18, .003, .12, (1, .3)) for f in (440, 392, 330)] + [tone(262, .4, .003, .35, (1, .3))])
save('fail.wav', x, .6)
# countdown tick
save('tick.wav', tone(1000, .08, .001, .07, (1, .2)), .45)
# water pour loop: filtered noise with bubbly modulation
d = 2.0; n = int(SR * d); noise = rng.standard_normal(n)
k = np.exp(-np.arange(40) / 6); k /= k.sum(); low = np.convolve(noise, k, 'same')
bub = np.zeros(n)
for _ in range(60):
    s = rng.integers(0, n - 2000); f0 = rng.uniform(500, 1400); tt = t(.04)
    bub[s:s + len(tt)] += np.sin(2 * np.pi * (f0 + 3000 * tt) * tt) * np.exp(-tt * 90) * .6
x = low * .8 + bub
fade = int(.05 * SR); x[:fade] *= np.linspace(0, 1, fade); x[-fade:] *= np.linspace(1, 0, fade)
save('pour.wav', x, .5)
# pencil scribble
n = int(SR * .5); noise = rng.standard_normal(n); hp = noise - np.convolve(noise, np.ones(8) / 8, 'same')
am = .5 + .5 * np.sin(2 * np.pi * 14 * t(.5)); save('draw.wav', hp * am * env(n, .02, .05), .3)
# splash / spill
tt = t(.5); noise = rng.standard_normal(len(tt)); lowp = np.convolve(noise, np.ones(12) / 12, 'same')
save('splash.wav', lowp * np.exp(-tt * 7), .6)
# reward fanfare (bottle full / water color)
x = np.concatenate([tone(f, .11, .003, .07, (1, .5, .2)) for f in (659, 784, 880, 988, 1175)] + [tone(1319, .6, .003, .5, (1, .5, .2))])
save('reward.wav', x, .7)

# background music: gentle 8-bar loop (I-vi-IV-V) at 112 bpm
bpm = 112; beat = 60 / bpm; bars = 8; total = int(SR * beat * 4 * bars)
mus = np.zeros(total)
chords = [(262, 330, 392), (220, 262, 330), (175, 220, 262), (196, 247, 294)] * 2
melody = [659, 784, 880, 784, 659, 587, 523, 587, 523, 659, 587, 523, 440, 523, 587, 659,
          698, 659, 587, 523, 587, 659, 523, 440, 494, 587, 659, 587, 494, 440, 392, 494]
def place(sig, start):
    s = int(start * SR); e = min(total, s + len(sig)); mus[s:e] += sig[:e - s]
for b, ch in enumerate(chords):
    for q in range(4):
        st = (b * 4 + q) * beat
        place(tone(ch[0] / 2, beat * .9, .005, .2, (1, .3)) * .35, st)
        for f in ch: place(tone(f, beat * .45, .005, .15, (1, .15)) * .12, st + beat * .5)
for i, f in enumerate(melody):
    place(tone(f, beat * .95, .01, .25, (1, .35, .1)) * .3, i * beat)
save('music.wav', mus, .45)
print('ok')

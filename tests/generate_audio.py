"""Generate original PCM effects and seamless ambience from seeded synthesis."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050
RNG = np.random.default_rng(471908)

def noise(seconds, low=60, high=3500):
    count = round(seconds * RATE)
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    phase = RNG.uniform(0, 2*np.pi, frequencies.size)
    weights = np.zeros_like(frequencies)
    keep = (frequencies >= low) & (frequencies <= high)
    weights[keep] = 1 / np.sqrt(frequencies[keep])
    result = np.fft.irfft(weights * np.exp(1j * phase), n=count)
    return result / max(np.max(np.abs(result)), 1e-9)

def save(name, samples, loop=False):
    samples = np.asarray(samples)
    if not loop:
        fade = min(200, samples.size // 8)
        samples[:fade] *= np.linspace(0,1,fade)
        samples[-fade:] *= np.linspace(1,0,fade)
    samples = np.clip(samples, -.85, .85)
    with wave.open(str(ROOT / (name+'.wav')), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes((samples * 32767).astype('<i2').tobytes())

seconds = 16
x = np.arange(seconds*RATE)/RATE
save('sea', noise(seconds,90,3100) * (.25 + .13*np.sin(2*np.pi*x/seconds) + .05*np.sin(4*np.pi*x/seconds)), True)
save('wind', noise(seconds,50,1100) * (.18 + .05*np.sin(2*np.pi*x/seconds+.5)), True)
x = np.arange(4*RATE)/RATE
fire = noise(4,120,4500)*.11
for center in [.17,.59,1.01,1.62,2.17,2.71,3.21,3.73]:
    fire += noise(4,1800,6500)*np.exp(-((x-center)/.011)**2)*.16
save('fire',fire,True)
for surface, band in [('sand',(240,3600)),('grass',(140,2200))]:
    x=np.arange(round(.19*RATE))/RATE
    save('step_'+surface,noise(.19,*band)*np.exp(-x*28)*.48)
x=np.arange(round(.19*RATE))/RATE
save('step_wood',noise(.19,100,1700)*np.exp(-x*27)*.34+np.sin(2*np.pi*210*x)*np.exp(-x*32)*.10)
x=np.arange(round(.30*RATE))/RATE
save('chop',noise(.30,160,2600)*np.exp(-x*22)*.53 + np.sin(2*np.pi*150*x)*np.exp(-x*30)*.13)
save('hammer',noise(.30,80,2400)*np.exp(-x*30)*.35 + np.sin(2*np.pi*260*x)*np.exp(-x*22)*.14)
x=np.arange(round(.45*RATE))/RATE
save('mine',noise(.45,1100,6500)*np.exp(-x*24)*.4 + (np.sin(2*np.pi*1830*x)+.5*np.sin(2*np.pi*2780*x))*np.exp(-x*14)*.1)
save('rustle',noise(.45,500,4500)*np.sin(np.pi*x/.45)**2*.3)
x=np.arange(round(.75*RATE))/RATE
save('splash',noise(.75,350,5200)*np.exp(-x*6)*.43 + np.sin(2*np.pi*(430*x-180*x*x))*np.exp(-x*9)*.10)
x=np.arange(round(.32*RATE))/RATE
save('consume',noise(.32,100,1800)*np.exp(-x*14)*.22)
x=np.arange(round(.16*RATE))/RATE
save('ui',np.sin(2*np.pi*620*x)*np.exp(-x*35)*.12)
print('Generated',len(list(ROOT.glob('*.wav'))),'original WAV assets')

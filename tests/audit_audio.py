"""Validate shipped PCM assets; audio-device audition remains a separate check."""
from pathlib import Path
from array import array
import wave, math, sys
root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
expected = {'sea','wind','fire','step_sand','step_grass','step_wood','chop','mine','hammer','rustle','splash','consume','ui'}
assert {p.stem for p in root.glob('*.wav')} == expected
for path in sorted(root.glob('*.wav')):
    with wave.open(str(path)) as reader:
        assert reader.getnchannels() == 1 and reader.getsampwidth() == 2
        assert reader.getframerate() == 22050 and reader.getnframes() >= 2000
        values = array('h', reader.readframes(reader.getnframes()))
    if sys.byteorder != 'little': values.byteswap()
    peak = max(abs(value) for value in values)
    rms = math.sqrt(sum(value*value for value in values) / len(values))
    assert 100 < peak < 30000 and 100 < rms < 12000, (path.name, peak, rms)
    if path.stem in {'sea','wind','fire'}:
        differences = [abs(values[i]-values[i-1]) for i in range(1,len(values))]
        seam = abs(values[-1]-values[0])
        assert seam <= max(differences), (path.name, 'loop seam exceeds signal transitions')
print('AUDIO AUDIT: 13/13 valid mono PCM assets, no clipped or silent files, loop seams within signal transitions')

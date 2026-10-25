# v0.4.1 large-screen acceptance

Accepted on 2026-10-24 with Connect IQ SDK 9.3.0. All 12 production, test and
snapshot targets compile without warnings. All 345 native VM test executions
pass (22 on each button-only model, 31 on each touch model); six host checks
and exact font regeneration checks pass.

The three larger profiles add four numeric faces, keeping original faces as
width-constrained fallbacks. Cadence, speed, elapsed time, average power and
remaining distance use the largest face that fits; full decimal strings have
priority over rounding. Statistics spacing uses actual glyph ink bounds.
Colon spacing remains visible in packed timestamps. No per-model UI copy is
required. The original 246×322 geometry and font assets remain unchanged.

All 12 default native screenshots were exported again; [screens.json](screens.json)
records their dimensions and SHA256 values. Edge 840's 12 native states were
also re-exported and are RGB-identical to the v0.3.15 baseline:
[pixel report](../edge840/pixel-regression.json).

Additional native captures cover long strings (`300.5mi(-200.5)`), four-digit
power, three-digit cadence/speed and missing sensors on 1040, 850 and 1060.
Native simulator clicks confirm power, statistics and graph range switching on
850 and 1060. [Gallery](../../screenshots.md) · [interaction log](../manual-interactions.txt).

[metrics.json](metrics.json) records nominal point sizes before and after the
change; actual selection depends on value width. Reference v0.4.0 images:
[1040](before/edge1040.png), [850](before/edge850.png), [1060](before/edge1060.png).
New native images are linked from the gallery and repository README.

Single-field snapshot heap usage is 58,296–104,040 of 127,424 bytes. This is
measured snapshot usage, not a claim about peak usage during an entire ride.
[Memory record](../field-memory.json) · [VM matrix](../vm-matrix.json).

Versioned v0.4.1 sideload downloads are published alongside immutable v0.4.0
files. The signed Store IQ covers all 17 regional product numbers. Store upload
and review submission are left to the owner; no Store submission was made.

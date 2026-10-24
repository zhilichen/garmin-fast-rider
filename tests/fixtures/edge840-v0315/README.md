# Edge 840 v0.3.15 reference

These 12 native 246×322 PNGs were captured from commit
`a22c5e620207855bf8dfbda6d68a401af92f13d4` before the multi-device refactor.
An isolated copy of that source used demo time `t=0.0` and local clock15:47.
The production source and metrics were not otherwise changed. Each combination
was selected through simulator taps and exported with File → Save Screen Capture.

Names describe power averaging, statistics mode and graph range:
`{3s,10s}-{all,lap}-{5m,20m,all}.png`.

`font-assets.json` records the original PNG/FNT/XML SHA256 values. The 246×322
profile retains these files byte for byte. Candidate captures and RGB comparison
results are in `docs/validation/edge840` at the repository root.

Do not replace the reference to hide an unintended regression. An intentional
840 design change should explicitly update the reference and explain the change
in review. Recorded-image checks do not substitute for exporting new native
frames after a renderer change.

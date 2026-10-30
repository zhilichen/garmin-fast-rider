# Native glyph profiles

Generated from the openly licensed files in `third_party/fonts` by `scripts/generate-fonts.py`. Each resolution directory shares the same 16 base roles and resource IDs, in runtime order:

Primary58, Live38, Average54, Meta18, Chart26, Stats32, Average36, Stats30, ZoneDigit44, SmallZ16, SmallZ10, Climb18, Units18, Remaining24, Remaining22, Remaining21.

Names retain840 reference sizes; actual sizes scale with profile width and are recorded in `config/display/<resolution>/FontInk.mc`. The smallest statistics/remaining fallback rounds down to preserve complete decimal strings. All PNGs contain grayscale coverage on black; XML explicitly enables font antialiasing. Native drawing uses the current theme background and retains the final raster row.

Profiles with `emphasize_numbers` append LiveEmphasis, StatsEmphasis, AverageEmphasis and RemainingEmphasis. Candidate lists and font loading are generated alongside their ink metrics. Larger screens try these faces first and retain the original roles as width fallbacks. Run `generate-project.py` after regenerating fonts so its statistics row spacing uses the updated ink bounds.

The original 16 246×322 glyph assets remain byte-for-byte identical to v0.3.15. Normal builds consume committed assets; Pillow is only needed for regeneration and visual checks. See `THIRD_PARTY_NOTICES.md` for source font licenses.

The current runtime has30 roles at246×322 and36 on emphasized profiles. Side-value, summary-label, compact-primary, enlarged-remaining and reduced-seconds roles are appended; existing role indices stay fixed. `MetaDisplay18` is a resource-only39-character subset loaded at the Meta18 role; a pixel/metric test compares every retained glyph with the original complete atlas.

Fonts load on demand. An LRU keeps16 resources on modern graphics runtimes and6 on older ones, selected through a guarded graphics capability check. Layout and ink metadata do not depend on whether a font is currently cached.

`SummaryValue46` adds a full-width bold numeric role for the compact paused rows. Enlarged live metrics keep four tall/narrow roles (68/60/54/46 reference sizes); riding distance reuses those roles with the unit/remaining column kept separate.

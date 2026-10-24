# Native glyph profiles

Generated from the openly licensed files in `third_party/fonts` by `scripts/generate-fonts.py`. Each resolution directory shares the same 16 semantic roles and resource IDs, in runtime order:

Primary58, Live38, Average54, Meta18, Chart26, Stats32, Average36, Stats30, ZoneDigit44, SmallZ16, SmallZ10, Climb18, Units18, Remaining24, Remaining22, Remaining21.

Names retain840 reference sizes; actual sizes scale with profile width and are recorded in `config/display/<resolution>/FontInk.mc`. The smallest statistics/remaining fallback rounds down to preserve complete decimal strings. All PNGs contain grayscale coverage on black; XML explicitly enables font antialiasing. Native drawing uses the white page background and retains the final raster row.

The 246×322 assets remain byte-for-byte identical to v0.3.15. Normal builds consume committed assets; Pillow is only needed for regeneration and visual checks. See `THIRD_PARTY_NOTICES.md` for source font licenses.

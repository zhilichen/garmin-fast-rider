# README visuals

The project homepage reuses the road-cycling [Store campaign](../../store/campaign/v0.4.1/README.md): the same male rider, cycling sunglasses, paved-road scenery and original Edge 840 screen captures. Hero and feature cards are referenced directly, without duplicate exports.

`developer-map.png` is a separate, editable architecture illustration in that visual style. Its device counts and resolutions come from `config/devices.json`:

```bash
python3 scripts/render-readme.py
```

This optional documentation export needs Node.js and `sharp`; use `NODE` / `NODE_PATH` if needed. It does not run during application builds. Typography and diagram shapes are code-native SVG; the raster export works in GitHub's light and dark themes. Its textual equivalent is the source map in both READMEs.

The original rider and scenery were created with built-in imagegen; their [prompts and hashes](../../store/campaign/v0.4.1/PROMPTS.json) are recorded. Actual device imagery in the campaign comes from the official SDK skin, with unmodified native UI captures and only an exterior silhouette clip. Garmin retains its device-design and trademark rights; the code license does not grant those rights.

`day-night.png` compares two unmodified native Edge 840 captures inside the official simulator exterior. Rebuild it with `python3 scripts/render-theme-preview.py` after capturing both themes. This optional export also needs the installed Edge 840 SDK device package (`CIQ_DEVICE_HOME`, or the SDK Manager download location). All layout and text are SVG; the night image uses the app's actual renderer, not an inverted or recolored day screenshot.

`ride-summary.png` uses unmodified native v0.4.6 stopped-view captures in both themes, with the same official Edge 840 exterior. Rebuild with `python3 scripts/render-summary-preview.py` using the same optional Node/sharp setup.

`zone-gauges.png` shows native v0.4.4 number-only badges and tapered fill gauges in both themes, in the official Edge 840 exterior. Rebuild with `python3 scripts/render-zones-preview.py`.

`live-cells.png` shows the native v0.4.5 large live numerals and vertical labels, inside the official Edge 840 exterior. Rebuild with `python3 scripts/render-live-cells-preview.py`.

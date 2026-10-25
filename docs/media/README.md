# README visuals

The project homepage reuses the road-cycling [Store campaign](../../store/campaign/v0.4.1/README.md): the same male rider, cycling sunglasses, paved-road scenery and original Edge 840 screen captures. Hero and feature cards are referenced directly, without duplicate exports.

`developer-map.png` is a separate, editable architecture illustration in that visual style. Its device counts and resolutions come from `config/devices.json`:

```bash
python3 scripts/render-readme.py
```

This optional documentation export needs Node.js and `sharp`; use `NODE` / `NODE_PATH` if needed. It does not run during application builds. Typography and diagram shapes are code-native SVG; the raster export works in GitHub's light and dark themes. Its textual equivalent is the source map in both READMEs.

The original rider and scenery were created with built-in imagegen; their [prompts and hashes](../../store/campaign/v0.4.1/PROMPTS.json) are recorded. Actual device imagery in the campaign comes from the official SDK skin, with unmodified native UI captures and only an exterior silhouette clip. Garmin retains its device-design and trademark rights; the code license does not grant those rights.

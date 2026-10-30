# Third-party font notices

FastRider code is MIT-licensed. The following unmodified font files, and bitmap glyph subsets generated from them, have separate licenses:

| Files | Attribution | License |
| --- | --- | --- |
| `RobotoCondensed-Bold.ttf`, `RobotoCondensed-Regular.ttf` | Font data copyright Google 2014 | [Apache License 2.0](third_party/fonts/LICENSE-Apache-2.0.txt) |
| `DejaVuSans_Cd_SemiBold_WGL4.ttf` | Copyright 2003 Bitstream, Inc.; Copyright 2006 Tavmjong Bah; DejaVu changes are in public domain | [Bitstream Vera and Arev notices](third_party/fonts/LICENSE-DejaVu.txt) |

The files under `third_party/fonts` are the exact openly licensed faces used by the original 840 implementation, obtained from the local Connect IQ font installation. Their embedded copyright/license records are retained. No other SDK binaries or fonts are redistributed.

`scripts/generate-fonts.py` creates modified, renamed BMFont PNG/FNT subsets such as Primary58 and Meta18, including the documented small-Z weight and compact-parenthesis adjustments. The TTF sources remain unmodified. Generated subsets preserve the same underlying font licenses and are covered by the above attributions.

Include this notice and both font licenses when distributing compiled FastRider packages. `scripts/package.py` does so automatically. Upstream references: [Roboto](https://github.com/googlefonts/roboto), [DejaVu font license](https://dejavu-fonts.github.io/License.html).

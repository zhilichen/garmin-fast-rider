import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def palette(path, prefix=''):
    return {name: int(value, 16) for name, value in re.findall(
        r'const ' + prefix + r'(\w+) = 0x([0-9A-F]+);', path.read_text())}


def luminance(rgb):
    channels = [((rgb >> shift) & 255) / 255 for shift in (16, 8, 0)]
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in channels]
    return sum(c * weight for c, weight in zip(linear, (.2126, .7152, .0722)))


def contrast(a, b):
    lo, hi = sorted((luminance(a), luminance(b)))
    return (hi + .05) / (lo + .05)


class ThemeReadabilityTests(unittest.TestCase):
    def test_numeric_colors_contrast_with_both_backgrounds(self):
        day = palette(ROOT / 'source/ui/DisplayRules.mc')
        night = palette(ROOT / 'source/ui/DisplayTheme.mc', 'NIGHT_')
        colors = ('GRAY', 'BLUE', 'GREEN', 'ORANGE', 'RED', 'PURPLE')
        for name in colors:
            # Large bold data values: exceed the 3:1 large-text floor in daylight.
            self.assertGreaterEqual(contrast(day[name], 0xFFFFFF), 4, name)
            # Night anchors are chosen on the older MIP 64-color RGB cube.
            rgb = night[name]
            self.assertTrue(all(((rgb >> s) & 255) % 85 == 0 for s in (16, 8, 0)), name)
            self.assertGreaterEqual(contrast(rgb, 0), 5, name)
        for name in ('INK', 'LABEL'):
            self.assertGreaterEqual(contrast(day[name], 0xFFFFFF), 7, name)
            self.assertGreaterEqual(contrast(night[name], 0), 7, name)

    def test_effort_colors_remain_distinct_on_mip_displays(self):
        night = palette(ROOT / 'source/ui/DisplayTheme.mc', 'NIGHT_')
        colors = [night[name] for name in ('GRAY', 'BLUE', 'GREEN', 'ORANGE', 'RED', 'PURPLE')]
        self.assertEqual(len(set(colors)), 6)
        for i, a in enumerate(colors):
            for b in colors[i + 1:]:
                distance = math.sqrt(sum((((a >> s) & 255) - ((b >> s) & 255)) ** 2 for s in (16, 8, 0)))
                self.assertGreaterEqual(distance, 120)


if __name__ == '__main__':
    unittest.main()

import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('import_course', Path(__file__).resolve().parents[1]/'scripts/import_course.py')
course = importlib.util.module_from_spec(spec)
spec.loader.exec_module(course)


class CourseImportTests(unittest.TestCase):
    def test_sample_preserves_endpoints_and_memory_bound(self):
        points = [(37+i*0.0001, -122, 100+i) for i in range(1000)]
        rows, ascent = course.sample(points)
        self.assertEqual(len(rows), 160)
        self.assertEqual(rows[0][1:], points[0])
        self.assertEqual(rows[-1][1:], points[-1])
        self.assertEqual(ascent, 999)
        self.assertTrue(all(a[0] < b[0] for a, b in zip(rows, rows[1:])))

    def test_missing_elevation_and_disjoint_tracks_rejected(self):
        invalid = ['<gpx><trk><trkseg><trkpt lat="0" lon="0"/></trkseg></trk></gpx>',
                   '<gpx><trk><trkseg/><trkseg/></trk></gpx>',
                   '<gpx><rte/><rte/></gpx>']
        for xml in invalid:
            with tempfile.TemporaryDirectory() as tmp:
                path = Path(tmp)/'route.gpx'
                path.write_text(xml)
                with self.assertRaises(ValueError):
                    course.read_gpx(path)

    def test_duplicate_points_do_not_divide_by_zero(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'route.gpx'
            path.write_text('<gpx><trk><trkseg><trkpt lat="37" lon="-122"><ele>100</ele></trkpt><trkpt lat="37" lon="-122"><ele>100</ele></trkpt><trkpt lat="37.001" lon="-122"><ele>110</ele></trkpt></trkseg></trk></gpx>')
            _, points = course.read_gpx(path)
            self.assertEqual(len(points), 2)
            rows, _ = course.sample(points)
            self.assertGreater(rows[-1][0], 100)


if __name__ == '__main__':
    unittest.main()

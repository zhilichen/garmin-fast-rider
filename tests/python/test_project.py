import importlib.util,json,re,unittest,hashlib,xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image,ImageChops

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('project_generator',ROOT/'scripts/generate-project.py')
project=importlib.util.module_from_spec(spec);spec.loader.exec_module(project)

class DeviceProjectTests(unittest.TestCase):
    def test_generated_files_match_catalog_and_shared_design(self):
        for name,expected in project.contents().items():
            self.assertEqual((ROOT/name).read_text(),expected,name)

    def test_all_devices_use_shared_sources_and_correct_input(self):
        data=json.loads((ROOT/'config/devices.json').read_text())
        jungle=(ROOT/'monkey.jungle').read_text()
        for name,d in data['devices'].items():
            selected=re.search(r'^'+name+r'\.sourcePath = (.*)$',jungle,re.M)[1]
            self.assertIn('$(base.sourcePath)',selected)
            self.assertIn('source/input/'+('touch' if d['touch'] else 'buttons'),selected)
            self.assertIn('config/display/'+d['profile'],selected)
        self.assertEqual({n for n,d in data['devices'].items() if not d['touch']},{'edge530','edge540','edge550'})

    def test_840_fonts_are_original_assets(self):
        for name,sha in json.loads((ROOT/'tests/fixtures/edge840-v0315/font-assets.json').read_text()).items():
            actual = ROOT/'resources/fonts/246x322'/name
            if name == 'fonts.xml':
                original = ROOT/'tests/fixtures/edge840-v0315/fonts.xml'
                self.assertEqual(hashlib.sha256(original.read_bytes()).hexdigest(),sha)
                baseline = list(ET.fromstring(original.read_bytes()))
                current = list(ET.fromstring(actual.read_bytes()))
                self.assertEqual([f.attrib for f in current[:len(baseline)]],[f.attrib for f in baseline])
            else:
                self.assertEqual(hashlib.sha256(actual.read_bytes()).hexdigest(),sha,name)

    def test_full_decimal_distance_fits_every_profile(self):
        chars='0123456789.-()mi'
        for folder in (ROOT/'config/display').iterdir():
            ink=(folder/'FontInk.mc').read_text();layout=(folder/'Layout.mc').read_text()
            lo=json.loads(re.search('NUMERIC_LEFT = (.*);',ink)[1]);hi=json.loads(re.search('NUMERIC_RIGHT = (.*);',ink)[1])
            gap=int(re.search('const PACKED_GAP = (.*);',layout)[1]);available=int(re.search('const RIGHT_WIDTH = (.*);',layout)[1])
            def width(text,font):return sum(hi[font][chars.index(c)]-lo[font][chars.index(c)] for c in text)+(len(text)-1)*gap
            for main,rest in [('300.5','(-200.5)'),('888.8','(-999.9)')]:
                self.assertLessEqual(width(main,4)+gap+width('mi',12)+gap+width(rest,15),available,folder.name)

    def test_recorded_840_native_regression(self):
        before=ROOT/'tests/fixtures/edge840-v0315';after=ROOT/'docs/validation/edge840'
        captures=list(before.glob('*.png'));self.assertEqual(len(captures),12)
        for p in captures:
            a=Image.open(p).convert('RGB');b=Image.open(after/p.name).convert('RGB')
            self.assertEqual(a.size,(246,322));self.assertEqual(b.size,a.size)
            self.assertIsNone(ImageChops.difference(a,b).getbbox(),p.name)

    def test_emphasized_rows_have_real_ink_clearance(self):
        profiles=json.loads((ROOT/'config/devices.json').read_text())['profiles']
        for name,profile in profiles.items():
            if not profile.get('emphasize_numbers',False):continue
            folder=ROOT/'config/display'/name
            ink=(folder/'FontInk.mc').read_text();layout=(folder/'Layout.mc').read_text()
            def metric(key):return json.loads(re.search('const '+key+' = (.*);',ink)[1])
            def anchor(key):return int(re.search('const '+key+' = (.*);',layout)[1])
            top,bottom=metric('TOP'),metric('BOTTOM')
            self.assertEqual(len(metric('SIZES')),26)
            self.assertGreater(metric('NUMERIC_RIGHT')[16][16],metric('NUMERIC_LEFT')[16][16])
            self.assertLess(anchor('STATS_TITLE_BASELINE')+bottom[3]+1,anchor('STATS_TIME_BASELINE')-top[16],name)
            self.assertLess(anchor('STATS_TIME_BASELINE')+bottom[16]+1,anchor('STATS_AVERAGE_BASELINE')-top[18],name)
            self.assertLess(anchor('STATS_AVERAGE_BASELINE')+bottom[18]+1,anchor('STATS_DISTANCE_BASELINE')-top[17],name)

if __name__=='__main__':unittest.main()

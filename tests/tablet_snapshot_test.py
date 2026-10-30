"""Checks comparison of controlled pickups and rejection of misleading exports."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

path = Path(__file__).resolve().parents[1] / 'tools' / 'compare_tablet_snapshots.py'
spec = importlib.util.spec_from_file_location('tablet_diff', path)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)


class SnapshotTest(unittest.TestCase):
    def read(self, text):
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory) / 'snapshot.tsv'
            p.write_text(text)
            return mod.load(p)

    def sample(self, count=0, opened=0, build=24250053):
        return f'FORMAT\tFFRS_TABLET_PICKUPS_V1\nBUILD\t{build}\nSHARD_INVENTORY\t{count}\nPICKUP\t2016\t4294967295\t2\t{opened}\t0\t{opened}\nEND\tOK\n'

    def test_controlled_pickup(self):
        delta, changes = mod.compare(self.read(self.sample()), self.read(self.sample(1, 1)))
        self.assertEqual(delta, 1)
        self.assertEqual(changes, [((2016, 2), (4294967295, 0, 0, 0), (4294967295, 1, 0, 1))])

    def test_rejects_partial_export(self):
        with self.assertRaises(ValueError):
            self.read(self.sample().replace('END\tOK\n', ''))

    def test_rejects_duplicate_keys(self):
        with self.assertRaises(ValueError):
            self.read(self.sample().replace('END\tOK', 'PICKUP\t2016\t-1\t2\t1\t0\t1\nEND\tOK'))

    def test_rejects_build_mismatch(self):
        with self.assertRaises(ValueError):
            mod.compare(self.read(self.sample()), self.read(self.sample(build=1)))

    def test_distinguishes_added_and_removed_records(self):
        first = self.read(self.sample())
        second = self.read(self.sample().replace('\t2\t0\t0\t0', '\t3\t0\t0\t0'))
        _, changes = mod.compare(first, second)
        self.assertEqual([entry[0] for entry in changes], [(2016, 2), (2016, 3)])


if __name__ == '__main__':
    unittest.main()

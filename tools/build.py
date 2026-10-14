"""Build a single HTTP-loadable file from the readable source modules."""
from pathlib import Path
import argparse

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true', help='Fail if Library.lua is out of date')
args = parser.parse_args()
parts = ['-- AngelUI 1.0.0 | MIT | Obsidian (c) 2025 deividcomsono\n',
         '--[[\n' + (root/'LICENSE').read_text(encoding='utf-8') + '\n]]\n',
         'local Obsidian = (function()\n', (root/'vendor/Obsidian.lua').read_text(encoding='utf-8'), '\nend)()\n']
for name in ['Persistence', 'Style', 'Overlays', 'Library']:
    parts += [f'local {name} = (function()\n', (root/f'src/{name}.lua').read_text(encoding='utf-8'), '\nend)()\n']
parts += ['return Library(Obsidian, Style, Overlays, Persistence)\n']
result = ''.join(parts)
destination = root/'Library.lua'
if args.check:
    assert destination.read_text(encoding='utf-8') == result, 'Run python tools/build.py and commit Library.lua'
else:
    destination.write_text(result, encoding='utf-8')
print('AngelUI bundle is current' if args.check else 'Built Library.lua')

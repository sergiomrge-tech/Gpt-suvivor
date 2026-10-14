"""Audit this independent Godot project, including formatted asset paths."""
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors = []
files = []
for path in root.rglob('*'):
    relative = path.relative_to(root)
    if not path.is_file() or any(part in {'.git', '.godot', '__pycache__'} for part in relative.parts):
        continue
    files.append(path)
    if path.suffix in {'.tmp', '.log', '.bak', '.pyc', '.zip', '.apk', '.jks', '.keystore', '.password'}:
        errors.append(f'Unexpected file: {relative}')
    if path.suffix in {'.gd', '.tscn', '.godot', '.gdshader'}:
        for ref in re.findall(r'[\"\'](res://[^\"\'\n]+)[\"\']', path.read_text(encoding='utf-8')):
            local = ref[6:]
            # printf-style templates must match at least one actual resource;
            # the catalog checks below validate every generated actor/theme ID.
            pattern = re.sub(r'%[sd]', '*', local)
            pattern = re.sub(r'\*+', '*', pattern)
            if not any(candidate.is_file() for candidate in root.glob(pattern)):
                errors.append(f'Broken reference in {relative}: {ref}')
for required in ['project.godot', 'scenes/main.tscn', 'scripts/game.gd', 'scripts/actor.gd',
                 'scripts/world.gd', 'scripts/progression.gd', 'scripts/content.gd',
                 'scripts/touch_controls.gd', 'data/catalog.json', 'assets/ART_LICENSE.md',
                 'assets/FONT_LICENSE.txt', 'tests/test_game.gd', 'tests/test_combat_bot.gd']:
    if not (root / required).is_file():
        errors.append(f'Missing source: {required}')
catalog = json.loads((root / 'data/catalog.json').read_text(encoding='utf-8'))
for index in range(6):
    if not (root / f'assets/world_{index}.png').is_file():
        errors.append(f'Missing world theme {index}')
for actor in ['varek', 'maela', 'neris', 'knight', 'archer', 'brute', 'garron',
              'severan', 'sereia', 'colosso', 'rei', 'varek_hammer', 'maela_focus', 'neris_daggers']:
    if not (root / f'assets/{actor}.png').is_file():
        errors.append(f'Missing actor atlas {actor}')
if len(catalog['items']) != 120 or len(catalog['dungeons']) != 15:
    errors.append('Unexpected catalog size')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'DUNGEONS AUDIT PASSED: {len(files)} files, 0 broken references, 0 unexpected package files')

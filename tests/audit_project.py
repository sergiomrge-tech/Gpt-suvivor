"""Audit local res:// references, package hygiene and source completeness."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors = []
files = []
for path in root.rglob('*'):
    relative = path.relative_to(root)
    if any(part in {'.git', '.godot', '__pycache__'} for part in relative.parts) or not path.is_file():
        continue
    # Each nested Godot project has its own res:// root and validation suite.
    # Match the editor's boundary instead of interpreting its files as Survivor.
    if any((parent / 'project.godot').is_file() for parent in path.parents if parent != root and root in parent.parents):
        continue
    files.append(path)
    if path.suffix in {'.tmp', '.log', '.bak', '.pyc', '.zip', '.apk'}:
        errors.append(f'Unexpected file: {relative}')
    if path.suffix in {'.gd', '.tscn', '.godot', '.gdshader'}:
        source = path.read_text(encoding='utf-8')
        for ref in re.findall(r'res://[A-Za-z0-9_./-]+', source):
            if not (root / ref[6:]).is_file():
                errors.append(f'Broken reference in {relative}: {ref}')
for required in ['project.godot', 'scenes/main.tscn', 'scripts/game.gd', 'scripts/world.gd', 'scripts/survival_state.gd', 'scripts/save_manager.gd', 'scripts/touch_button.gd', 'tests/test_survivor.gd']:
    if not (root / required).is_file():
        errors.append(f'Missing source: {required}')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'AUDIT PASSED: {len(files)} source/documentation files, 0 broken references, 0 unexpected package files')

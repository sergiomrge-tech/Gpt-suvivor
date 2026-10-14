#!/usr/bin/env python3
"""Configure only 3D asset images for platform VRAM compression; keep UI lossless.
Godot reimports matching images before baking/export. Source image bytes stay intact.
"""
from pathlib import Path
import re
count=0
for root in ['assets/real_world','assets/real_nature','assets/survival_props','assets/characters']:
    for path in Path(root).rglob('*.import'):
        if path.name.lower().endswith(('.jpg.import','.png.import','.jpeg.import')):
            text=path.read_text()
            if 'importer="texture"' not in text:
                continue
            text=re.sub(r'^compress/mode=.*$', 'compress/mode=2',text,flags=re.M)
            text=re.sub(r'^compress/high_quality=.*$', 'compress/high_quality=false',text,flags=re.M)
            text=re.sub(r'^mipmaps/generate=.*$', 'mipmaps/generate=true',text,flags=re.M)
            if root != 'assets/characters':
                text=re.sub(r'^process/size_limit=.*$', 'process/size_limit=1024',text,flags=re.M)
            if '_nor_gl' in path.name or '_normal' in path.name:
                text=re.sub(r'^compress/normal_map=.*$', 'compress/normal_map=1',text,flags=re.M)
            path.write_text(text)
            count+=1
print(f'MOBILE_TEXTURE_PROFILES: {count} photographed 3D textures; UI unchanged')

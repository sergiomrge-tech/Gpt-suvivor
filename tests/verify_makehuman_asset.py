#!/usr/bin/env python3
"""Validate original source GLB structure without Blender/Godot dependencies."""
import json, struct, sys
from pathlib import Path
file = Path(sys.argv[1] if len(sys.argv)>1 else "assets/characters/makehuman_survivor.glb")
data = file.read_bytes()
assert data[:4] == b"glTF" and struct.unpack_from("<I",data,4)[0] == 2, "not GLB v2"
assert struct.unpack_from("<I",data,8)[0] == len(data), "truncated GLB"
size, chunk_type = struct.unpack_from("<II",data,12)
assert chunk_type == 0x4E4F534A, "missing JSON chunk"
doc = json.loads(data[20:20+size])
meshes = doc.get("meshes",[])
skins = doc.get("skins",[])
animations = doc.get("animations",[])
nodes = doc.get("nodes",[])
assert meshes and skins and animations, "asset must have skinned meshes and clips"
joint_ids = set(i for s in skins for i in s.get("joints",[]))
joint_names = {str(nodes[i].get("name","")) for i in joint_ids}
assert len(joint_ids) >= 20, f"insufficient real skeleton bones: {len(joint_ids)}"
assert any("hand" in n.lower() and ("r" in n.lower() or "right" in n.lower()) for n in joint_names), "no hand bone for tools"
names = {str(a.get("name","")).lower() for a in animations}
assert "idle" in names and "walk" in names and "run" in names, f"missing locomotion clips: {names}"
tex_count = len(doc.get("textures",[]))
assert tex_count>=1, "missing authored PBR/diffuse texture"
print("RIGGED_MAKEHUMAN_PASS",file.stat().st_size,"bytes",len(joint_ids),"joints",len(meshes),"meshes",len(animations),"clips",tex_count,"textures")
print("BONE_HAND_CANDIDATES",sorted(n for n in joint_names if "hand" in n.lower()))
print("ANIMATIONS",sorted(names))

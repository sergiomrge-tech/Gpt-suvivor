# GPT Survivor v1.9 — Genuine rigged MakeHuman character

First real swap from handmade character geometry to imported human.glb:
- Verified pinned CC0 MakeHuman/MPFB2 human from vsim open-source repository (2.77 MB).
- glTF 2.0 with 53 bones, one skinned mesh, four native clips (`idle`, `walk`, `run`, `wave`) and embedded material texture.
- `scripts/skinned_survivor.gd` imports `Skeleton3D`/`AnimationPlayer`, dynamically normalizes scale, binds existing crafted tools and fishing rod to the real `hand_r` bone through `BoneAttachment3D`.
- Legacy body remains hidden as error-safe backup. All survival gameplay, player movement, saving, resource crafting and boat systems untouched.
- Bound material/pose/fishing validation and genuine Godot screenshot workflow. No APK.
- IMPORTANT: this imported source asset is a starting base; clothing, model styling, rig animations for chopping/building and physical device benchmarks require further refinement. Do not call it AAA photorealism.

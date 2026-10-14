#!/usr/bin/env python3
"""Stage original Poly Haven CC0 downloads as compact, texture-preserving glTF assets.

Run on GitHub Actions with node/npm + @gltf-transform/cli. Materialize the
cataloged downloads from the dedicated archive branch, verify upstream bytes,
then simplify meshes with meshoptimizer and save self-contained GLB files.
This intentionally keeps ZIP source packs out of the Android project.
"""
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile

SOURCE_REF = "origin/assets/cc0-trees-rocks-structures-oct2026"
ROOT = Path("assets/real_nature")
MODELS = ROOT/"models"
PACKS = "asset_downloads/2026-10-13/"
EXPECTED = {
    "island_tree_01":("Arvores_e_Troncos",0.045,0.075),
    "tree_stump_01":("Arvores_e_Troncos",0.37,0.015),
    "dead_tree_trunk_02":("Arvores_e_Troncos",0.30,0.020),
    "boulder_01":("Pedras_e_Paredoes",0.32,0.017),
    "rock_07":("Pedras_e_Paredoes",0.45,0.012),
    "rock_face_01":("Pedras_e_Paredoes",0.53,0.012),
    "wooden_ladder_02":("Estruturas_e_Utilitarios",0.75,0.009),
}
def tracked_blob(rel: str) -> bytes:
    return subprocess.check_output(["git","show",SOURCE_REF+":"+PACKS+rel])
def safe_unzip(pack: zipfile.ZipFile,name: str,target: Path):
    target.mkdir(parents=True,exist_ok=True)
    prefix = name+"/"
    for info in pack.infolist():
        if not info.filename.startswith(prefix) or info.is_dir():
            continue
        short=info.filename[len(prefix):]
        path=Path(short)
        if path.is_absolute() or ".." in path.parts or not short:
            raise RuntimeError("Dangerous source archive entry "+info.filename)
        dest=target/path
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(pack.read(info))
def run():
    catalog=json.loads(tracked_blob("CATALOGO_CC0.json"))
    upstream={v["id"]:v for v in catalog["assets"]}
    assert set(EXPECTED)==set(upstream), "Staged all seven downloaded models; no substitutions"
    MODELS.mkdir(parents=True,exist_ok=True)
    output={"license":"CC0","license_url":"https://polyhaven.com/license",
            "game":"GPT Survivor","date":"2026-10-13","stage":"mobile_GLTF_optimized",
            "tool":"@gltf-transform/cli@4.2.1 simplify / meshoptimizer",
            "items":[]}
    all_files={}
    for name,(group,ratio,error) in EXPECTED.items():
        zipfile_name=group+"_CC0_Realista.zip"
        if zipfile_name not in all_files:
            raw=tracked_blob(zipfile_name)
            expected_hash=catalog["groups"][group]["sha256"]
            assert hashlib.sha256(raw).hexdigest()==expected_hash, group+" archive SHA256 mismatch"
            all_files[zipfile_name]=raw
        original=upstream[name]
        with zipfile.ZipFile(io.BytesIO(all_files[zipfile_name])) as z:
            assert z.testzip() is None
            with tempfile.TemporaryDirectory(prefix="survivor-cc0-") as temp:
                folder=Path(temp)/name
                safe_unzip(z,name,folder)
                for dep in original["files"]:
                    b=(folder/dep["path"]).read_bytes()
                    assert hashlib.sha256(b).hexdigest()==dep["sha256"],(name,dep["path"])
                inp=folder/(name+".gltf")
                out=MODELS/(name+".glb")
                cmd=["npx","--yes","@gltf-transform/cli@4.2.1","simplify",str(inp),str(out),
                     "--ratio",str(ratio),"--error",str(error)]
                print("SIMPLIFY_CC0",name,ratio,flush=True)
                subprocess.run(cmd,check=True,timeout=600)
                b=out.read_bytes()
                if len(b)<100_000 or b[:4]!=b"glTF" or int.from_bytes(b[8:12],"little")!=len(b):
                    raise RuntimeError(name+" is not a nonempty valid GLB container")
                if len(b)>32_000_000:
                    raise RuntimeError(name+" optimized model unexpectedly >32MB")
                output["items"].append({"id":name,"source":original["page"],"source_sha256":original["files"][0]["sha256"],
                                        "original_triangles":None,"ratio":ratio,"error":error,
                                        "output":str(out),"size":len(b),"sha256":hashlib.sha256(b).hexdigest(),
                                        "license":"CC0"})
                print("VALID_OPTIMIZED_GLB",name,len(b),flush=True)
    (ROOT/"MOBILE_ASSET_CATALOG.json").write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("CC0_MOBILE_MODELS_COMPLETE",len(output["items"]),sum(x["size"] for x in output["items"]),flush=True)

if __name__=="__main__":
    run()

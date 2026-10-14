#!/usr/bin/env python3
"""Download real Poly Haven CC0 1k glTF/GLB model packages for GPT Survivor.

Store untouched upstream model+dependencies, pin hashes, pack by category and
verify local references. The game does not automatically import this staging pack.
"""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import time
import urllib.request
import zipfile

OUT = Path("asset_downloads/2026-10-13")
UA = {"User-Agent": "GPT-Survivor-Island-CC0-Catalog/2.1 (+https://github.com/sergiomrge-tech/Gpt-suvivor)"}
GROUPS = {
    "Arvores_e_Troncos": ["island_tree_01", "island_tree_03", "tree_stump_01", "dead_tree_trunk_02"],
    "Pedras_e_Paredoes": ["boulder_01", "rock_07", "rock_face_01"],
    "Estruturas_e_Utilitarios": ["wooden_ladder_02"],
}
MAX_FILE_BYTES = 105_000_000  # Do not commit an unexpectedly huge source into a game repo.
MAX_GROUP_BYTES = 95_000_000 # GitHub has a 100 MB per-file limit.
def get(url: str, limit=MAX_FILE_BYTES) -> bytes:
    last = None
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req,timeout=100) as stream:
                stated = stream.headers.get("Content-Length")
                if stated and int(stated)>limit:
                    raise ValueError("File over source limit: "+url)
                buf=stream.read(limit+1)
            if len(buf)>limit or not buf:
                raise ValueError("Bad size: "+url)
            return buf
        except Exception as exc:
            last=exc
            time.sleep(attempt*2+1)
    raise RuntimeError("Could not fetch %s: %r" % (url,last))
def api(path):
    return json.loads(get("https://api.polyhaven.com/"+path,12_000_000))
def choose(variants):
    for resolution in ("1k","2k"):
        if resolution in variants and "gltf" in variants[resolution]:
            return resolution, "gltf", variants[resolution]["gltf"]
        if resolution in variants and "glb" in variants[resolution]:
            return resolution, "glb", variants[resolution]["glb"]
    raise ValueError("No 1k/2k glTF/GLB source")
def save_asset(name):
    info=api("info/"+name)
    assert info.get("type")==2, (name,"not a model")
    assert info.get("date_published",0) < 1790000000, (name,"unpublished")
    formats=api("files/"+name)
    res,ext,primary=choose(formats.get("gltf",formats.get("glb",{})))
    sources={name+"."+ext:primary}
    for dep_name,entry in primary.get("include",{}).items():
        rel=PurePosixPath(dep_name)
        if rel.is_absolute() or ".." in rel.parts or not entry.get("url"):
            raise ValueError("Unsafe/broken glTF dependency: "+str(dep_name))
        sources[str(rel)] = entry
    loaded={}
    record=[]
    for rel,src in sources.items():
        raw=get(src["url"])
        wanted=src.get("md5")
        got=hashlib.md5(raw).hexdigest()
        if wanted and wanted != got:
            raise RuntimeError("%s checksum mismatch %s" %(name,rel))
        if rel.endswith(".gltf"):
            doc=json.loads(raw)
            assert doc.get("asset",{}).get("version")=="2.0"
        elif rel.endswith(".glb"):
            assert raw[:4]==b"glTF", (name,rel)
        loaded[rel]=raw
        record.append({"path":rel,"size":len(raw),"sha256":hashlib.sha256(raw).hexdigest(),"source_url":src["url"],"md5":got})
    if ext=="gltf":
        model=json.loads(loaded[name+".gltf"])
        refs=[d.get("uri","") for d in model.get("buffers",[])+model.get("images",[])]
        for uri in refs:
            if uri.startswith("data:"):
                continue
            if uri not in loaded:
                raise RuntimeError("%s missing referenced dependency %s"%(name,uri))
    meta={"id":name,"title":info.get("name",name),"license":"CC0","provider":"Poly Haven","page":"https://polyhaven.com/a/"+name,"resolution":res,"format":ext,"files":record}
    return loaded,meta
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    catalog={"license":"CC0","usage":"Commercial game use allowed; inspect mesh LODs and mobile performance before adding to Godot gameplay","source_license":"https://polyhaven.com/license","assets":[],"failures":[],"groups":{}}
    for group,names in GROUPS.items():
        zip_path=OUT/(group+"_CC0_Realista.zip")
        accepted=[]
        with zipfile.ZipFile(zip_path,"w",zipfile.ZIP_DEFLATED,compresslevel=5) as archive:
            for name in names:
                try:
                    loaded,meta=save_asset(name)
                    # Prevent one 4M-triangle tree from filling the mobile production repository.
                    candidate_size=sum(len(v) for v in loaded.values())
                    if candidate_size>80_000_000:
                        raise ValueError("source too large (%d bytes): excluded until LOD optimization"%candidate_size)
                    for rel,data in loaded.items():
                        archive.writestr(name+"/"+rel,data)
                    archive.writestr(name+"/ASSET_SOURCE.json",json.dumps(meta,indent=2,ensure_ascii=False))
                    accepted.append(meta)
                    catalog["assets"].append(meta)
                    print("DOWNLOADED_CC0",group,name,len(loaded),"files",candidate_size,"bytes",flush=True)
                except Exception as e:
                    print("SKIPPED_CC0",group,name,str(e),flush=True)
                    catalog["failures"].append({"id":name,"reason":str(e)})
        if not accepted:
            zip_path.unlink(missing_ok=True)
            catalog["groups"][group]={"status":"none","assets":[]}
            continue
        if zip_path.stat().st_size>MAX_GROUP_BYTES:
            zip_path.unlink()
            catalog["groups"][group]={"status":"too_large_for_git","assets":[x["id"] for x in accepted]}
            catalog["failures"].append({"id":group,"reason":"group ZIP exceeds GitHub 100MB file limit"})
            continue
        # Read back every zipped original and assert SHA256.
        with zipfile.ZipFile(zip_path) as z:
            assert z.testzip() is None
            for entry in accepted:
                for file in entry["files"]:
                    blob=z.read(entry["id"]+"/"+file["path"])
                    assert hashlib.sha256(blob).hexdigest()==file["sha256"]
        catalog["groups"][group]={"status":"downloaded_and_verified","assets":[x["id"] for x in accepted],
                                  "zip":zip_path.name,"bytes":zip_path.stat().st_size,"sha256":hashlib.sha256(zip_path.read_bytes()).hexdigest()}
    (OUT/"CATALOGO_CC0.json").write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("NATURE_PACK_RESULTS",json.dumps({"downloaded":len(catalog["assets"]),"skipped":len(catalog["failures"]),"groups":catalog["groups"]}),flush=True)
    if len([g for g in catalog["groups"].values() if g["status"]=="downloaded_and_verified"])<2:
        raise SystemExit("At least two verified asset categories required")
if __name__=="__main__":
    main()

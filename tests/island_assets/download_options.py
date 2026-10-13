#!/usr/bin/env python3
"""Download REAL CC0 Poly Haven vegetation and PBR samples for selection only.
No world replacement, never copies unoptimized scans into the Android build.
"""
from pathlib import Path
import hashlib, json, time, urllib.request, urllib.error

BASE=Path("out/island_pbr_options")
API="https://api.polyhaven.com"
HEADERS={"User-Agent":"GPT-Survivor-Asset-Evaluation/1.0"}
MAX_FILE=46*1024*1024
SETS={
    "A_praia_tropical":{
        "materials":["aerial_beach_01","palm_tree_bark"],
        "models":["fern_02","anthurium_botany_01"],
    },
    "B_selva_densa":{
        "materials":["coast_sand_05","coast_sand_rocks_02"],
        "models":["calathea_orbifolia_01","pachira_aquatica_01"],
    },
    "C_costa_selvagem":{
        "materials":["aerial_beach_02","seaside_rock"],
        "models":["coast_rocks_05"],
    },
}
REQUIRED={"diff","nor_gl","rough"}
def fetch(url, destination=None):
    last=None
    for attempt in range(4):
        try:
            req=urllib.request.Request(url,headers=HEADERS)
            with urllib.request.urlopen(req,timeout=60) as r:
                data=r.read()
            if destination:
                destination.parent.mkdir(parents=True,exist_ok=True)
                destination.write_bytes(data)
            return data
        except Exception as e:
            last=e
            time.sleep(attempt+1)
    raise RuntimeError(f"Download failed: {url}: {last}")

def api(path):
    return json.loads(fetch(API+path))

def selected_resolution(formats):
    for k in ["1k","2k","4k"]:
        if k in formats: return k
    return next(iter(formats))

def flat_items(entries):
    for k,v in entries.items():
        if not isinstance(v,dict):continue
        for k2,v2 in v.items():
            if isinstance(v2,dict) and "url" in v2:
                yield (k,k2,v2)

def download_entry(entry,dest):
    size=int(entry.get("size",0))
    if size>MAX_FILE:
        print("SKIPPING_OVERSIZE",dest,size,flush=True)
        return False
    raw=fetch(entry["url"],dest)
    if entry.get("md5"):
        actual=hashlib.md5(raw).hexdigest()
        assert actual==entry["md5"],("MD5 mismatch",dest)
    print("DOWNLOADED",dest,len(raw),flush=True)
    return True

report={"sets":{},"license":"CC0 1.0 Universal","source":"Poly Haven API, https://polyhaven.com/"}
for title,contents in SETS.items():
    folder=BASE/title
    folder.mkdir(parents=True,exist_ok=True)
    rec={"models":[],"materials":[]}
    for slug in contents["materials"]+contents["models"]:
        is_model=slug in contents["models"]
        info=api("/info/"+slug)
        files=api("/files/"+slug)
        preview=folder/"previews"/(slug+".png")
        # The actual thumbnail hosted by Poly Haven. Not an AI image.
        preview_ok=False
        for address in [
            f"https://cdn.polyhaven.com/asset_img/thumbs/{slug}.png?width=700&height=500",
            f"https://cdn.polyhaven.org/asset_img/thumbs/{slug}.png?width=700&height=500",
        ]:
            try:
                fetch(address,preview)
                preview_ok=True
                break
            except Exception as e:print("PREVIEW_RETRY",slug,str(e)[:70],flush=True)
        record={"id":slug,"name":info.get("name",slug),"url":"https://polyhaven.com/a/"+slug,
                "preview":str(preview.relative_to(BASE)) if preview_ok else None,
                "source_resolution":"1k","tris":info.get("attributes",{}).get("triangles"),
                "files":[],"size_bytes":0,"warnings":[]}
        if is_model:
            variants=files.get("gltf",{})
            if not variants:
                record["warnings"].append("No glTF download variant in API")
            else:
                res=selected_resolution(variants)
                entry=variants[res].get("gltf",{})
                dest=folder/"models"/slug/(slug+".gltf")
                if entry.get("url") and download_entry(entry,dest):
                    record["files"].append(str(dest.relative_to(BASE)))
                dependencies=entry.get("include",{})
                for dep_name,dep in dependencies.items():
                    if not isinstance(dep,dict) or not dep.get("url"):continue
                    dep_path=Path(dep_name)
                    if dep_path.is_absolute() or ".." in dep_path.parts:raise ValueError(dep_name)
                    target=folder/"models"/slug/dep_path
                    if download_entry(dep,target):
                        record["files"].append(str(target.relative_to(BASE)))
                record["source_resolution"]=res
        else:
            for map_kind in sorted(REQUIRED):
                variants=files.get(map_kind,{})
                if not variants:
                    record["warnings"].append("Missing map "+map_kind)
                    continue
                res=selected_resolution(variants)
                fmt_items=variants[res]
                fmt=next((x for x in ["jpg","png"] if x in fmt_items),None)
                if fmt is None:
                    record["warnings"].append("Missing jpg/png map "+map_kind)
                    continue
                entry=fmt_items[fmt]
                dest=folder/"textures"/slug/(slug+"_"+res+"_"+map_kind+"."+fmt)
                if download_entry(entry,dest):
                    record["files"].append(str(dest.relative_to(BASE)))
        record["size_bytes"]=sum((BASE/path).stat().st_size for path in record["files"])
        (folder/(slug+".json")).write_text(json.dumps(record,indent=2,ensure_ascii=False))
        rec["models" if is_model else "materials"].append(record)
    report["sets"][title]=rec
BASE.mkdir(exist_ok=True,parents=True)
(BASE/"CATALOGO.json").write_text(json.dumps(report,ensure_ascii=False,indent=2))
(BASE/"LICENSE_CC0.txt").write_text(
    "Original assets downloaded for evaluation from Poly Haven (https://polyhaven.com), CC0 1.0 Universal. "
    "Asset IDs, source links and original filenames are listed in CATALOGO.json. "
    "Samples are not optimized for Android or placed into the installed game.\n")
print("CATALOG_COMPLETE",json.dumps({k:len(v["models"])+len(v["materials"]) for k,v in report["sets"].items()}),flush=True)

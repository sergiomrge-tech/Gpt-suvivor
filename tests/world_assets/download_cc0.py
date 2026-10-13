#!/usr/bin/env python3
"""Download inspectable, genuinely licensed CC0 sources for GPT Survivor.
Commit originals to a dedicated feature branch; do not include in main until
a native Godot game/render + regression gate has passed.
"""
import hashlib, json, struct, pathlib, time, urllib.request
ROOT=pathlib.Path("assets/real_world")
HEAD={"User-Agent":"GPT-Survivor-Island-Research/1.0"}
BASE="https://www.innerscene.com/api/library/"
PARTS={
 "airplane_propeller":("single-engine-propeller-aircraft-d6091ef1","Avião monomotor, material real, base para destroços"),
 "palm_detailed":("palm-detailed-a8777b8c","Palmeira 16 frondes/960 folíolos, fonte próxima"),
 "palm_light":("palm-light-20c2a70c","Palmeira 16 frondes/480 folíolos, fonte LOD distante"),
 "workbench_carpenter":("carpenter-workbench-carpentry-workbench-9855fae6","Bancada de carpinteiro"),
 "garden_shed":("garden-shed-2-x-3-m-original-exterior-model-80b9ac4b","Abrigo de referência, não uma estrutura automaticamente construída"),
}
POLY_MODELS=["fern_02","calathea_orbifolia_01","pachira_aquatica_01"]
POLY_TEXTURES=["aerial_beach_01","coast_sand_05","coast_sand_rocks_02","seaside_rock"]
def fetch(url):
    for attempt in range(4):
        try:
            req=urllib.request.Request(url,headers=HEAD)
            with urllib.request.urlopen(req,timeout=90) as r:
                return r.read()
        except Exception as e:
            if attempt==3:raise RuntimeError(f"Failed downloading {url}: {e}")
            time.sleep(2*(attempt+1))
def store(path,data,maximum=30_000_000):
    assert 0 < len(data) < maximum,(path,len(data))
    path.parent.mkdir(exist_ok=True,parents=True)
    path.write_bytes(data)
    return {"path":str(path.relative_to(ROOT)),"size":len(data),"sha256":hashlib.sha256(data).hexdigest()}
def jsonapi(slug):
    return json.loads(fetch("https://api.polyhaven.com/"+slug))
def pick(variants,prefer=("1k","2k")):
    for r in prefer:
        if r in variants:return r
    return next(iter(variants))
def tex_variant(d,k):
    aliases={"diff":("diff","Diffuse","diffuse","albedo"),"nor_gl":("nor_gl","Normal (GL)","norGL"),"rough":("rough","Rough","roughness","Roughness")}[k]
    return next((d[x] for x in aliases if x in d),None)
catalog={"license":"CC0","items":[],"sources":["https://www.innerscene.com/tools/library/","https://polyhaven.com/license"]}
for name,(page,label) in PARTS.items():
    url=BASE+page+"/download"
    data=fetch(url)
    assert data[:4]==b"glTF" and struct.unpack_from("<I",data,4)[0]==2,(name,data[:70])
    assert struct.unpack_from("<I",data,8)[0]==len(data)
    loc=store(ROOT/"models"/(name+".glb"),data)
    catalog["items"].append({"id":name,"title":label,"kind":"glb","provider":"Innerscene","license":"CC0","web":"https://www.innerscene.com/tools/library/3d-parts/"+page,"files":[loc]})
    print("LICENSED_CC0_GLB",name,len(data),flush=True)
for name in POLY_MODELS:
    desc=jsonapi("info/"+name); d=jsonapi("files/"+name)
    formats=d.get("gltf",{})
    assert formats,("no gltf",name)
    res=pick(formats)
    entry=formats[res]["gltf"]
    assert entry.get("url"),(name,"missing gltf")
    folder=ROOT/"models"/"polyhaven"/name
    group=[store(folder/(name+".gltf"),fetch(entry["url"]))]
    for dep_name,dep in entry.get("include",{}).items():
        if not isinstance(dep,dict) or not dep.get("url"):continue
        rel=pathlib.PurePosixPath(dep_name)
        assert ".." not in rel.parts and not rel.is_absolute()
        group.append(store(folder/dep_name,fetch(dep["url"]),maximum=28_000_000))
    catalog["items"].append({"id":name,"title":desc.get("name",name),"kind":"gltf","provider":"Poly Haven","license":"CC0","web":"https://polyhaven.com/a/"+name,"files":group})
    print("LICENSED_CC0_TROPICAL_PLANT",name,len(group),flush=True)
for name in POLY_TEXTURES:
    desc=jsonapi("info/"+name); d=jsonapi("files/"+name)
    group=[]
    for kind in ("diff","nor_gl","rough"):
        versions=tex_variant(d,kind)
        assert versions,(name,kind,"missing maps")
        res=pick(versions)
        entry=versions[res].get("jpg",versions[res].get("png"))
        assert entry,(name,kind)
        ext="jpg" if versions[res].get("jpg") else "png"
        group.append(store(ROOT/"textures"/name/(name+"_"+kind+"."+ext),fetch(entry["url"])))
    catalog["items"].append({"id":name,"title":desc.get("name",name),"kind":"pbr","provider":"Poly Haven","license":"CC0","web":"https://polyhaven.com/a/"+name,"files":group})
    print("LICENSED_CC0_PBR",name,len(group),flush=True)
ROOT.mkdir(parents=True,exist_ok=True)
(ROOT/"CATALOG.json").write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+"\n")
assert len(catalog["items"]) == len(PARTS)+len(POLY_MODELS)+len(POLY_TEXTURES)
print("WORLD_CC0_ASSETS_READY",len(catalog["items"]),flush=True)

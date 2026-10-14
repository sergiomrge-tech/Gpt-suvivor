"""Clean, align, sign and verify an APK exported from this project.
Signing key stays outside the repository. SDK tools must be supplied explicitly.
"""
import argparse,zipfile,subprocess,secrets,os,hashlib,json
from pathlib import Path

def run(cmd):subprocess.run([str(x) for x in cmd],check=True)

def main():
 p=argparse.ArgumentParser();p.add_argument('unsigned');p.add_argument('output');p.add_argument('--build-tools',required=True);p.add_argument('--key-directory',required=True)
 args=p.parse_args();src=Path(args.unsigned);out=Path(args.output);out.parent.mkdir(exist_ok=True,parents=True);tools=Path(args.build_tools);keys=Path(args.key_directory);keys.mkdir(exist_ok=True,parents=True)
 key=keys/'dungeons_fires.jks';password=keys/'dungeons_fires.password'
 if not key.exists():
  if not password.exists():password.write_text(secrets.token_urlsafe(32));password.chmod(0o600)
  run(['keytool','-genkeypair','-keystore',key,'-alias','dungeonsfires','-storepass:file',password,'-keypass:file',password,'-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=Dungeons Fires, O=Independent Games, C=BR'])
  key.chmod(0o600)
 clean=out.with_suffix('.unsigned.apk');aligned=out.with_suffix('.aligned.apk');removed=[]
 root=Path(__file__).resolve().parents[1]
 with zipfile.ZipFile(src) as z,zipfile.ZipFile(clean,'w') as target:
  for entry in z.infolist():
   n=entry.filename
   signature=n=='META-INF/MANIFEST.MF' or (n.startswith('META-INF/') and n.count('/')==1 and n.endswith(('.RSA','.DSA','.EC','.SF')))
   if n.startswith(('assets/tests/','assets/tools/')) or signature:removed.append(n);continue
   target.writestr(entry,z.read(n))
  for name in ['FONT_LICENSE.txt','ART_LICENSE.md']:
   target.write(root/'assets'/name,'assets/licenses/'+name,compress_type=zipfile.ZIP_DEFLATED)
 run([tools/'zipalign','-f','-P','16','4',clean,aligned])
 run([tools/'apksigner','sign','--ks',key,'--ks-key-alias','dungeonsfires','--ks-pass','file:'+str(password),'--out',out,aligned])
 run([tools/'apksigner','verify','--verbose',out])
 run([tools/'zipalign','-c','-P','16','4',out])
 with zipfile.ZipFile(out) as z:
  assert z.testzip() is None
  assert 'assets/data/catalog.json' in z.namelist()
  assert not any(n.startswith(('assets/tests/','assets/tools/')) or n.endswith(('.jks','.keystore','.password')) for n in z.namelist())
  catalog=json.loads(z.read('assets/data/catalog.json'));assert len(catalog['items'])==120
 report={'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'bytes':out.stat().st_size,'removed_internal_files':removed,'crc':'passed','signature':'passed','alignment_16kb':'passed','engine':'4.6.1','device_installation':'not tested'}
 out.with_suffix('.verification.json').write_text(json.dumps(report,indent=2))
 clean.unlink();aligned.unlink()
 if out.with_suffix(out.suffix+'.idsig').exists():out.with_suffix(out.suffix+'.idsig').unlink()
 print(json.dumps(report))

if __name__=='__main__':main()

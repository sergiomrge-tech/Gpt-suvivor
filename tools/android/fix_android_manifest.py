"""Fix Godot 4.6.1 APK export assigning FileProvider authority to AndroidX Startup.
Only AndroidManifest.xml bytes are changed; APK must be aligned and signed afterwards.
"""
import argparse, struct, zipfile
from pathlib import Path

def fix(data):
    pool_start=8
    kind,header_size,pool_size,count,style_count,flags,strings_start,styles_start=struct.unpack_from('<HHI5I',data,pool_start)
    assert kind==1 and style_count==0 and flags==0, 'Expected UTF-16 unstyled AXML string pool'
    offsets=struct.unpack_from('<'+'I'*count,data,pool_start+header_size)
    strings=[]
    for offset in offsets:
        pos=pool_start+strings_start+offset
        length=struct.unpack_from('<H',data,pos)[0];pos+=2
        if length&0x8000:
            length=((length&0x7fff)<<16)|struct.unpack_from('<H',data,pos)[0];pos+=2
        strings.append(data[pos:pos+length*2].decode('utf-16le'))
    providers={}
    cursor=pool_start+pool_size
    while cursor<len(data):
        chunk,head,size=struct.unpack_from('<HHI',data,cursor)
        assert size>=head and size>0
        if chunk==0x102:
            _,name,attr_start,attr_size,attr_count=struct.unpack_from('<IIHHH',data,cursor+16)
            if strings[name]=='provider':
                attrs={}
                for index in range(attr_count):
                    pos=cursor+16+attr_start+index*attr_size
                    ns,attr_name,raw=struct.unpack_from('<III',data,pos)
                    typ=data[pos+15];value=struct.unpack_from('<I',data,pos+16)[0]
                    if typ==3:attrs[strings[attr_name]]=value
                if 'name' in attrs and 'authorities' in attrs:providers[strings[attrs['name']]]=attrs['authorities']
        cursor+=size
    startup=providers['androidx.startup.InitializationProvider']
    fileprovider=providers['androidx.core.content.FileProvider']
    assert startup!=fileprovider
    old=strings[startup]
    assert old==strings[fileprovider] and old.endswith('.fileprovider')
    strings[startup]=old.removesuffix('.fileprovider')+'.androidx-startup'
    encoded=bytearray();new_offsets=[]
    for string in strings:
        new_offsets.append(len(encoded));raw=string.encode('utf-16le');length=len(raw)//2
        assert length<0x8000
        encoded+=struct.pack('<H',length)+raw+b'\x00\x00'
    while len(encoded)%4:encoded.append(0)
    new_start=header_size+4*count
    new_size=new_start+len(encoded)
    pool=struct.pack('<HHI5I',kind,header_size,new_size,count,0,flags,new_start,0)
    pool+=struct.pack('<'+'I'*count,*new_offsets)+encoded
    result=bytearray(data[:pool_start]+pool+data[pool_start+pool_size:])
    struct.pack_into('<I',result,4,len(result))
    return bytes(result),strings[startup]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('output');args=parser.parse_args()
    with zipfile.ZipFile(args.input) as src,zipfile.ZipFile(args.output,'w') as out:
        for info in src.infolist():
            data=src.read(info.filename)
            if info.filename=='AndroidManifest.xml':data,authority=fix(data)
            out.writestr(info,data)
    with zipfile.ZipFile(args.input) as src,zipfile.ZipFile(args.output) as out:
        changed=[name for name in src.namelist() if src.read(name)!=out.read(name)]
        assert changed==['AndroidManifest.xml'];assert out.testzip() is None
    print('Changed only AndroidManifest.xml; Startup authority:',authority)
if __name__=='__main__':main()

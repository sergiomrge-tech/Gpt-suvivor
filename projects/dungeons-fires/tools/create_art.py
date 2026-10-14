"""Original deterministic pixel artwork and sound for Dungeons Fires.
No extracted franchise assets. Character animation is generated from drawn poses.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import math, random, wave, struct, json, shutil
ROOT=Path(__file__).resolve().parents[1]; A=ROOT/'assets'; A.mkdir(exist_ok=True)
PAL={'outline':'#171522','skin':'#d7a477','light':'#efc29b','shadow':'#8e5e49','steel':'#82919f','shine':'#c2d0d3','dark':'#414553','gold':'#d6aa5f'}

def sprite(kind,state,frame,weapon_override=''):
    im=Image.new('RGBA',(96,96));d=ImageDraw.Draw(im);p=frame/8*math.tau
    colors={'varek':('#58768a','#b64238'),'maela':('#714970','#df7941'),'neris':('#537552','#846549'),'knight':('#4e545d','#6b3438'),'archer':('#74634b','#4b4a4b'),'brute':('#81755d','#4e3634'),'garron':('#827b68','#a6362c'),'sereia':('#436f89','#c4d8d3'),'rei':('#a3bac3','#5b6081'),'colosso':('#956244','#b44631'),'severan':('#bcbcc7','#727b9c')}
    armor,cape=colors[kind]; hero=kind in ('varek','maela','neris');caster=kind in ('maela','sereia','severan');boss=kind in ('garron','sereia','rei','colosso','severan')
    bob=round(math.sin(p)*1.2) if state in ('idle','run') else 0
    move=state=='run';swing=math.sin(p) if move else 0
    lean=round(math.sin(frame/7*math.pi)*6) if state=='attack' else (7 if state=='dodge' else 0)
    cx=45+lean;cy=42+bob;fy=84
    if state=='hurt':cx-=3
    def poly(points,fill):d.polygon(points,fill=fill);d.line(points+[points[0]],fill=PAL['outline'],width=2)
    def limb(a,b,c,w,color):
        d.line([a,b,c],fill=PAL['outline'],width=w+4);d.line([a,b,c],fill=color,width=w)
        d.line([a,b],fill=PAL['shine'] if color==armor else PAL['light'],width=2)
    # cape in back, torn lower edge
    poly([(cx-12,cy-15),(cx+5,cy-14),(cx+6,cy+30),(cx-8,cy+34),(cx-5,cy+27),(cx-19,cy+30),(cx-17,cy+6)],cape)
    d.line((cx-11,cy-8,cx-13,cy+24),fill='#e07858' if kind=='varek' else armor,width=2)
    for side in (-1,1):
        hip=(cx+side*5,cy+14);knee=(cx+side*5+round(swing*side*8),cy+28)
        foot=(cx+side*6+round(swing*side*12),fy-round(max(0,swing*side)*4))
        limb(hip,knee,foot,7,armor if not caster else cape)
        poly([(foot[0]-5,foot[1]-8),(foot[0]+4,foot[1]-8),(foot[0]+7,foot[1]-1),(foot[0]-5,foot[1])],PAL['dark'])
        d.line((foot[0]-3,foot[1]-7,foot[0]+3,foot[1]-7),fill=PAL['gold'],width=2)
    if caster:poly([(cx-13,cy),(cx+12,cy),(cx+17,fy-7),(cx+3,fy-2),(cx-18,fy-5)],armor)
    poly([(cx-11,cy-13),(cx+9,cy-13),(cx+12,cy+10),(cx+7,cy+18),(cx-9,cy+17),(cx-14,cy+2)],armor)
    d.line((cx-8,cy-9,cx-7,cy+9),fill=PAL['shine'],width=2)
    d.line((cx-5,cy+2,cx+8,cy+2),fill=PAL['dark'],width=2)
    d.rectangle((cx-12,cy+11,cx+11,cy+15),fill='#503d32');d.rectangle((cx-1,cy+11,cx+4,cy+15),fill=PAL['gold'])
    for side in (-1,1):
        poly([(cx+side*12-6,cy-16),(cx+side*12+5,cy-14),(cx+side*12+6,cy-8),(cx+side*12-6,cy-7)],armor)
    shoulder=(cx+10,cy-7);elbow=(cx+18,cy+4);hand=(cx+21,cy+10)
    if state in ('attack','cast'):
        t=frame/7;angle=-1.9+t*3.7;hand=(round(cx+math.cos(angle)*25),round(cy+math.sin(angle)*25))
        elbow=(round((cx+hand[0])/2),round((cy+hand[1])/2))
    limb(shoulder,elbow,hand,6,PAL['skin'])
    d.ellipse((hand[0]-3,hand[1]-3,hand[0]+3,hand[1]+3),fill=PAL['light'])
    limb((cx-11,cy-7),(cx-17,cy+3),(cx-16,cy+13),6,armor)
    # face, hair and helmets
    hx=cx+1;hy=cy-26
    poly([(hx-7,hy-7),(hx+6,hy-6),(hx+7,hy+6),(hx+3,hy+11),(hx-5,hy+9),(hx-8,hy+2)],PAL['skin'])
    d.rectangle((hx-6,hy-9,hx+5,hy-5),fill='#3b2b28');d.rectangle((hx-9,hy-7,hx-6,hy+5),fill='#3b2b28')
    d.rectangle((hx+3,hy,hx+6,hy+1),fill=PAL['outline']);d.point((hx+5,hy),fill='white')
    d.line((hx+4,hy+5,hx+7,hy+5),fill=PAL['shadow'],width=1)
    if kind in ('varek','knight','garron','rei','colosso'):
        poly([(hx-10,hy-5),(hx-8,hy-12),(hx+5,hy-13),(hx+9,hy-6),(hx+6,hy-3),(hx-6,hy-4),(hx-7,hy+5),(hx-10,hy+3)],armor)
        d.line((hx-5,hy-11,hx+4,hy-11),fill=PAL['shine'],width=2)
        if boss:
            poly([(hx-8,hy-10),(hx-16,hy-18),(hx-14,hy-6)],PAL['gold']);poly([(hx+5,hy-11),(hx+13,hy-19),(hx+12,hy-5)],PAL['gold'])
    elif caster:
        poly([(hx-11,hy-9),(hx-2,hy-19),(hx+6,hy-12),(hx+9,hy-6)],cape)
        d.line((hx-4,hy-13,hx+4,hy-9),fill=PAL['gold'],width=2)
    else:d.line((hx-8,hy-4,hx+6,hy-4),fill=PAL['gold'],width=2)
    # equipment distinct by character
    x,y=hand
    if caster and weapon_override=='focus':
        d.ellipse((x-8,y-15,x+9,y+2),fill='#c77644',outline=PAL['gold'],width=2)
        d.ellipse((x-4,y-12,x+4,y-4),fill='#ffeac1')
    elif caster:
        d.line((x,y-35,x,y+22),fill=PAL['outline'],width=6);d.line((x,y-33,x,y+20),fill='#af8257',width=3)
        d.ellipse((x-6,y-41,x+6,y-29),fill='#e7aa60');d.ellipse((x-3,y-38,x+3,y-32),fill='#fff1bf')
    elif weapon_override=='daggers':
        d.line((x,y,x+17,y-14),fill=PAL['outline'],width=6);d.line((x,y,x+16,y-13),fill=PAL['shine'],width=3)
        d.line((cx-17,cy+13,cx-28,cy-3),fill=PAL['outline'],width=6);d.line((cx-17,cy+13,cx-27,cy-2),fill=PAL['shine'],width=3)
    elif kind in ('neris','archer'):
        d.arc((x-7,y-25,x+17,y+23),-80,80,fill=PAL['gold'],width=3);d.line((x+7,y-24,x+7,y+22),fill='#c2b095',width=1)
        d.line((x-14,y,x+23,y),fill=PAL['steel'],width=2)
    elif kind in ('brute','garron','colosso') or weapon_override=='hammer':
        d.line((x,y+14,x+14,y-23),fill='#573f31',width=5)
        poly([(x+4,y-27),(x+23,y-24),(x+23,y-13),(x+9,y-15)],PAL['steel']);d.line((x+7,y-25,x+21,y-22),fill=PAL['shine'],width=2)
    else:
        ang=-1.1
        if state=='attack':ang=-2.1+frame/7*3.1
        ex=round(x+math.cos(ang)*34);ey=round(y+math.sin(ang)*34)
        d.line((x,y,ex,ey),fill=PAL['outline'],width=7);d.line((x,y,ex,ey),fill=PAL['shine'],width=4)
        d.line((x-6,y-3,x+5,y+3),fill=PAL['gold'],width=3)
        poly([(cx-23,cy-2),(cx-12,cy-2),(cx-11,cy+16),(cx-17,cy+23),(cx-25,cy+15)],armor)
        d.line((cx-18,cy,cx-18,cy+17),fill=PAL['gold'],width=2)
    if state=='dodge':im=im.rotate(-20,resample=Image.Resampling.NEAREST,center=(48,72))
    if state=='death':im=im.rotate(-min(90,frame*15),resample=Image.Resampling.NEAREST,center=(48,76));alpha=im.getchannel('A').point(lambda v:int(v*(1-frame/10)));im.putalpha(alpha)
    return im

def bg(theme):
    rng=random.Random(417+theme); im=Image.new('RGB',(640,360));d=ImageDraw.Draw(im)
    palettes=[('#222634','#484350','#625647','#493f38'),('#142f3b','#36535b','#597269','#3b5150'),('#263650','#65758a','#9aa6ac','#647285'),('#392736','#784f43','#9e7650','#6b503d'),('#292c42','#686781','#a3a2b1','#6a6880'),('#222f3a','#56656a','#79705c','#554b3d')]
    sky,wall,light,floor=palettes[theme]
    for y in range(200):
        t=y/200;c=tuple(int(int(sky[i:i+2],16)*(1-t*.35)) for i in (1,3,5));d.line((0,y,640,y),fill=c)
    # distant serrated mountains and towers
    for layer in range(3):
        points=[(0,205)]+[(x,90+layer*25-rng.randrange(10,48)) for x in range(0,661,30)]+[(640,205)]
        d.polygon(points,fill=['#252e40','#2d3541','#343b46'][layer])
    d.ellipse((505,30,545,70),fill='#aeaca3');d.ellipse((497,25,532,61),fill=sky)
    # stone structure with arches
    for x in range(-10,650,130):
        d.rectangle((x,106,x+109,212),fill=wall)
        for row in range(5):
            for col in range(5):
                bx=x+col*23-(row%2)*11;by=108+row*20
                d.rectangle((bx,by,bx+21,by+18),outline='#292a32',fill=wall)
                d.line((bx+1,by+1,bx+19,by+1),fill=light)
                if rng.random()<.5:d.line((bx+5,by+7,bx+8,by+11),fill='#303139')
        d.rectangle((x+30,145,x+77,210),fill='#151a27');d.pieslice((x+30,119,x+77,167),180,360,fill='#151a27')
        for k in range(7):
            a=math.pi+k/6*math.pi;px=x+53+math.cos(a)*29;py=145+math.sin(a)*29
            d.rectangle((px-5,py-5,px+5,py+5),fill=light,outline='#353438')
        for px in (x+21,x+80):d.rectangle((px,146,px+7,213),fill=light);d.line((px+2,147,px+2,211),fill=wall)
    # floor tessellation perspective
    d.rectangle((0,210,640,359),fill=floor)
    for row,y in enumerate(range(211,360,19)):
        for x in range(-20,680,45):
            off=23 if row%2 else 0
            d.rectangle((x+off,y,x+off+42,y+16),outline='#343039')
            if rng.random()<.8:d.line((x+off+2,y+1,x+off+38,y+1),fill=light)
    # themed props
    for x in (12,200,440,602):
        if theme==0:
            d.polygon([(x,210),(x+12,111),(x+19,110),(x+9,212)],fill='#382c29');d.rectangle((x-3,130,x+30,138),fill='#594030')
            d.line((x+13,139,x+9,176),fill='#bb8e56',width=2)
        elif theme==1:
            d.rectangle((x,213,x+24,268),fill='#264b59');d.line((x,245,x+25,245),fill='#7aa8b1',width=2)
        elif theme==2:
            d.polygon([(x,214),(x+10,155),(x+23,214)],fill='#9dbbc2');d.line((x+10,155,x+10,211),fill='#d5e8e3',width=2)
        elif theme==3:
            d.rectangle((x,185,x+27,214),fill='#462f2b');d.rectangle((x+5,194,x+24,207),fill='#e69348');d.line((x+6,200,x+24,200),fill='#ffe0a0',width=2)
        elif theme==4:
            for by in range(149,204,8):d.rectangle((x,by,x+29,by+6),fill='#3b364a');d.line((x+7,by+1,x+7,by+5),fill='#bab1aa',width=2)
        else:
            d.rectangle((x,154,x+35,215),fill='#694a35');d.polygon([(x-10,155),(x+15,130),(x+47,155)],fill='#8c403b')
    # ground details
    for _ in range(290):
        x=rng.randrange(640);y=rng.randrange(220,359);d.line((x,y,x+rng.randrange(1,4),y),fill=light if rng.random()<.2 else '#3b373f')
    for x in (30,270,560):
        d.rectangle((x-3,181,x+3,218),fill='#412f29');d.rectangle((x-7,193,x+7,198),fill='#9f754e')
        d.polygon([(x-7,190),(x-4,178),(x+1,182),(x+4,170),(x+8,187),(x+2,194)],fill='#e89546');d.polygon([(x-3,189),(x+2,181),(x+4,190)],fill='#ffdf89')
    if theme==5:
        # central communal hearth and workbench
        d.rectangle((300,184,341,216),fill='#38363b');d.rectangle((307,190,335,214),fill='#ce7739');d.polygon([(310,213),(318,177),(325,192),(330,175),(335,212)],fill='#f4bf62')
        d.rectangle((121,208,175,215),fill='#775336');d.rectangle((126,215,130,232),fill='#48352b');d.rectangle((168,215,173,233),fill='#48352b')
    return im

def audio(name,duration,fn):
    rate=22050
    with wave.open(str(A/(name+'.wav')),'wb') as w:
        w.setparams((1,2,rate,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*22000)) for i in range(int(duration*rate))))

for name in ['varek','maela','neris','knight','archer','brute','garron','sereia','rei','colosso','severan']:
    sheet=Image.new('RGBA',(96*8,96*7))
    for row,state in enumerate(['idle','run','attack','dodge','hurt','death','cast']):
        for f in range(8):sheet.paste(sprite(name,state,f),(f*96,row*96))
    sheet.save(A/(name+'.png'))
for name,weapon in [('varek','hammer'),('maela','focus'),('neris','daggers')]:
    sheet=Image.new('RGBA',(96*8,96*7))
    for row,state in enumerate(['idle','run','attack','dodge','hurt','death','cast']):
        for f in range(8):sheet.paste(sprite(name,state,f,weapon),(f*96,row*96))
    sheet.save(A/(name+'_'+weapon+'.png'))
for i in range(6):bg(i).save(A/f'world_{i}.png')
rng=random.Random(33)
audio('swing',.18,lambda t:math.sin(t*4000*(1-t*3))*math.exp(-t*20)*.15)
audio('impact',.22,lambda t:(math.sin(2*math.pi*(110-t*220)*t)*.5+rng.uniform(-.13,.13))*math.exp(-t*22))
audio('magic',.5,lambda t:math.sin(2*math.pi*(460+t*200)*t)*math.exp(-t*8)*.22)
audio('coin',.35,lambda t:(math.sin(2*math.pi*880*t)+math.sin(2*math.pi*1320*t))*.15*math.exp(-t*13))
audio('step',.1,lambda t:rng.uniform(-.08,.08)*math.exp(-t*50))
notes=[146.83,174.61,220,196,146.83,130.81,174.61,146.83]
def music(t):
    f=notes[int(t/2)%len(notes)];phase=t%2;env=math.sin(math.pi*phase/2)**2
    return (math.sin(math.tau*f*t)*.07+math.sin(math.tau*f*2*t)*.022)*env+math.sin(math.tau*73.415*t)*.018*math.sin(math.pi*t/16)**2
audio('hearth',16,music)
icon=Image.new('RGB',(256,256),'#171923');di=ImageDraw.Draw(icon)
di.rounded_rectangle((12,12,244,244),radius=42,outline='#c9a35b',width=7)
di.polygon([(62,185),(81,98),(106,128),(125,45),(175,109),(194,165),(162,208),(89,208)],fill='#e9853c')
di.polygon([(96,186),(122,118),(143,145),(151,185),(135,213),(111,211)],fill='#ffe4a7')
di.line((47,205,207,49),fill='#c8d1cf',width=12);di.line((52,169,89,206),fill='#c9a35b',width=10)
icon.save(A/'icon.png')
shutil.copy('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',A/'DejaVuSans.ttf')
license=Path('/usr/share/doc/fonts-dejavu-core/copyright')
if license.exists():shutil.copy(license,A/'FONT_LICENSE.txt')
(A/'ART_LICENSE.md').write_text('Dungeons Fires: pixel art, animações e efeitos sonoros originais produzidos por código neste projeto. Nenhum sprite ou áudio extraído de Golden Axe. A fonte DejaVu Sans segue a licença anexada. Arte v0.1: padrão inicial sujeito a refinamento visual.\n')
print('Created original animated atlases, six environment kits, icon and audio.')

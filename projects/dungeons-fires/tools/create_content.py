from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
names=['Mina dos Sinos','Bosque Carbonizado','Fortaleza da Brasa Partida','Canais da Vigília','Ossuário Afogado','Catedral das Vozes Submersas','Aldeia do Último Inverno','Galerias de Vidro','Bastilha do Sol Preso','Caravana Petrificada','Fundição dos Exilados','Palácio de Ferro Rubro','Arquivo Sem Rostos','Ponte dos Ausentes','Coração do Véu']
bosses=['Capataz Rusk','Matriarca de Carvão','Garron, o Portão Vivo','Barqueiro Sem Rosto','Zelador de Cal','Sereia de Cinzas','Caçadora do Degelo','Sentinela de Quartzo','O Rei Enregelado','Coletor de Tributos','Mestra dos Cadinhos','Colosso das Correntes','Escriba Vazio','Vigia do Silêncio','Severan, o Custodiante']
story=['Doran: Os sinos da mina ainda chamam os trabalhadores. Traga minério e procure minha ferramenta.','Iria: O bosque guarda nomes nas raízes. Liberte-os do fogo que não aquece.','Iria: Garron era nosso guardião. Agora seu escudo é o portão de uma prisão.','Sava: Há sobreviventes nos canais. Escute as vozes que ainda respondem.','Oren: Os mortos não deveriam servir de muralha. Encontre quem os prende.','Iria: Cada sino daquela catedral carrega uma lembrança roubada.','Sava: O frio não acabou com a aldeia. O esquecimento acabou.','Doran: Vidro e gelo revelam aquilo que as paredes escondem.','Iria: O rei mantém o sol preso para que seu último dia nunca termine.','Neris: A caravana pagou o tributo com suas próprias histórias.','Doran: Os exilados ainda alimentam as fornalhas. Rompa suas correntes.','Oren: O colosso nasceu para proteger. Agora obedece apenas ao ferro.','Iria: Fui eu quem escreveu algumas dessas páginas. Vou responder por isso.','Maela: Os ausentes não pedem vingança. Pedem um caminho para o descanso.','Severan: Se a chama morrer, perderei minha filha outra vez. Iria: Ela precisa de liberdade, não de outra prisão.']
dungeons=[]
for i,n in enumerate(names):
    dungeons.append({'id':f'DUN_{i:02d}','name':n,'region':i//3,'boss':bosses[i],'guardian':i%3==2,'lore':story[i],'level':i*2+1,'rooms':5,'reward_gold':120+i*20,'reward_ore':10+i*2,'xp':70+i*20,'material':f'CORE_{i//3}' if i%3==2 else '', 'seed':400+i})
items=[]
families=[('sword','varek','Espada'),('hammer','varek','Martelo'),('staff','maela','Cajado'),('focus','maela','Foco'),('daggers','neris','Lâminas'),('bow','neris','Arco')]
suffixes=['da Vigília','de Fuligem','do Portão','das Marés','do Inverno','do Exílio','Rubro','do Nome Restaurado']
for family,hero,label in families:
    for i,s in enumerate(suffixes):items.append({'id':f'W_{family}_{i}','name':f'{label} {s}','slot':'weapon','family':family,'hero':hero,'attack':14+i*7,'defense':0,'tier':i,'rarity':min(3,i//2),'cost':60+i*70,'ore':8+i*5,'effect':'rupture' if family=='hammer' else 'none'})
for slot,label in [('head','Elmo'),('body','Cota'),('boots','Botas')]:
    for i in range(12):items.append({'id':f'A_{slot}_{i}','name':f'{label} {suffixes[i%8]} {i//8+1}','slot':slot,'hero':'all','attack':0,'defense':3+i*2,'tier':i//2,'rarity':min(3,i//3),'cost':45+i*35,'ore':4+i*2,'effect':'none'})
for i in range(24):items.append({'id':f'T_{i}','name':f'Talismã {suffixes[i%8]} {i//8+1}','slot':'talisman','hero':'all','attack':1+i//3,'defense':1+i//4,'tier':i//4,'rarity':min(3,i//6),'cost':70+i*20,'ore':6+i,'effect':'vitality' if i%2==0 else 'rupture'})
relics=['Marca do Portão','Eco das Marés','Coração do Inverno','Elo Rubro','Nome Restaurado','Sino de Doran','Fio da Memória','Selo do Caminho','Brasa da Casa','Vigília Serena','Página Recuperada','Centelha Livre']
for i,n in enumerate(relics):items.append({'id':f'R_{i}','name':n,'slot':'relic','hero':'all','attack':3+i,'defense':3+i,'tier':i if i<5 else 1,'rarity':3,'cost':100+i*30,'ore':0 if i<5 else 12,'core':f'CORE_{i}' if i<5 else '', 'effect':['guard','slow','resist','rupture','resource'][i%5]})
(R/'data/catalog.json').write_text(json.dumps({'schema':1,'regions':['Fronteira de Fuligem','Várzea dos Nomes','Coroa de Geada','Deserto das Fornalhas','Abismo Branco'],'dungeons':dungeons,'items':items},ensure_ascii=False,indent=2))
assert len(items)==120 and len(dungeons)==15
print('15 dungeons, 120 persistent item definitions')

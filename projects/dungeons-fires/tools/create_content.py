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
skill_specs={
 'varek':[('Investida da Forja','dash',2.0,5,0,'Avança e atinge inimigos na faixa à frente.'),('Guarda Ardente','guard',1.0,9,0,'Escudo temporário e bônus para o próximo ataque.'),('Fenda de Ferro','line',2.6,7,0,'Onda em linha que atravessa até três alvos.'),('Grito da Vigília','weaken',.8,10,0,'Enfraquece o dano dos inimigos próximos por 5 segundos.'),('Retorno da Brasa','riposte',3.2,6,0,'Contra-ataque após evitar um golpe com esquiva.'),('Muralha Viva','ward',1.1,12,0,'Campo protetor com escudo e lentidão nos inimigos.')],
 'maela':[('Dardo de Cinza','bolt',1.7,3,16,'Projétil rápido e preciso de baixo custo.'),('Círculo de Nomes','burn',.75,7,25,'Fogo persistente no chão por 4 segundos.'),('Selo Partido','mark',3.0,6,20,'Marca o alvo. Um golpe posterior detona o selo.'),('Véu Âmbar','shield',0,10,25,'Barreira que absorve dano por 6 segundos.'),('Corrente da Memória','chain',2.2,8,30,'Salta entre até três alvos com dano decrescente.'),('Vigília Incandescente','channel',1.0,12,35,'Campo contínuo poderoso com alcance limitado.')],
 'neris':[('Corte de Passagem','dash',1.9,4,0,'Deslocamento curto que corta a linha inimiga.'),('Marca da Caça','hunt',.8,7,0,'Marca um alvo para aumentar o dano por 5 segundos.'),('Disparo Perfurante','pierce',2.5,7,0,'Flecha perfurante ou corte em linha, conforme a arma.'),('Laço de Cinza','trap',1.7,8,0,'Armadilha que dispara uma vez e desacelera o alvo.'),('Passo do Ausente','decoy',1.0,9,0,'Deixa uma distração breve e reposiciona o herói.'),('Chuva de Estilhaços','rain',1.25,12,0,'Área persistente com flechas ou lâminas.')]
}
skills=[]
for hero,entries in skill_specs.items():
 for i,(name,mode,power,cd,mana,desc) in enumerate(entries):
  skills.append({'id':f'S_{hero}_{i}','hero':hero,'name':name,'mode':mode,'level':[1,4,8,12,18,24][i],'power':power,'cooldown':cd,'mana':mana,'description':desc})
branches={
 'varek':[('Bastilha',['hp','defense','heal','dodge','barrier','defense']),('Ruptura',['attack','rupture','skill','cooldown','crit','rupture']),('Fervor',['attack','movement','supreme','crit','cooldown','attack'])],
 'maela':[('Incêndio',['attack','skill','mana','crit','cooldown','skill']),('Sigilo',['skill','cooldown','supreme','crit','attack','skill']),('Vigília',['hp','defense','barrier','mana','dodge','barrier'])],
 'neris':[('Lâmina',['attack','crit','skill','movement','cooldown','attack']),('Sentinela',['attack','skill','supreme','crit','cooldown','skill']),('Passagem',['movement','dodge','hp','heal','barrier','dodge'])]
}
effects={'hp':(12,'vida'),'defense':(5,'defesa'),'heal':(.04,'eficácia de cura'),'dodge':(.04,'redução de recarga da esquiva'),'barrier':(.08,'eficácia de barreira'),'attack':(.025,'ataque'),'rupture':(.10,'ruptura de chefe'),'skill':(.045,'dano de técnica'),'cooldown':(.03,'redução de recarga das técnicas'),'crit':(.015,'chance crítica'),'movement':(.025,'velocidade'),'supreme':(.06,'ganho de Brasa'),'mana':(.10,'recuperação de mana')}
talents=[]
for hero,entries in branches.items():
 for branch,(name,keys) in enumerate(entries):
  for index,key in enumerate(keys):
   value,label=effects[key]
   capstone=index==5
   talents.append({'id':f'N_{hero}_{branch}_{index}','hero':hero,'branch':branch,'branch_name':name,'order':index,'name':f'{name}: '+['Fundação','Disciplina','Vigor','Domínio','Herança','Juramento'][index], 'max_rank':1 if capstone else 3,'requires_points':index*3,'sanctuary':1 if index<3 else (2 if index<5 else 3),'effect':key,'value':value*(3 if capstone else 1),'description':f'+{round(value*(3 if capstone else 1)*(100 if value<1 else 1),1)}'+('% ' if value<1 else ' ')+label+' por ponto.'})
quests=[]
for i,name in [(0,'A ferramenta de Doran'),(1,'Nomes nas raízes'),(2,'Libertar o Portão'),(5,'Vozes que retornam'),(8,'Um novo amanhecer'),(11,'O peso das correntes'),(14,'O último nome')]:
 quests.append({'id':f'Q_{i}','name':name,'dungeon':i,'barracks':1 if i<3 else 2,'gold':80+i*15,'ore':4+i,'ash':1,'text':story[i]})
room_profiles=[]
for i in range(15):
 rooms=[]
 for room in range(4):
  formation=[['knight','knight','archer'],['brute','archer','knight'],['archer','knight','archer','brute'],['brute','knight','knight']][(i+room)%4]
  rooms.append({'encounter':formation,'layout':(i*3+room)%4,'hazard':room in [1,2] and i>0,'treasure':room==2,'rest':room==3})
 room_profiles.append({'id':f'DUN_{i:02d}','rooms':rooms,'boss_pattern':['charge','roots','shield','hook','sweep','echo','rush','crystal','frost','hook','molten','chain','mirrors','rush','white'][i]})
(R/'data/catalog.json').write_text(json.dumps({'schema':2,'regions':['Fronteira de Fuligem','Várzea dos Nomes','Coroa de Geada','Deserto das Fornalhas','Abismo Branco'],'dungeons':dungeons,'items':items,'skills':skills,'talents':talents,'quests':quests,'encounters':room_profiles},ensure_ascii=False,indent=2))
assert len(items)==120 and len(dungeons)==15
assert len(skills)==18 and len(talents)==54
print('15 dungeons, 120 items, 18 skills, 54 talents, 7 story contracts')

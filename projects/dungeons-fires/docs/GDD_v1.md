# DUNGEONS FIRES
## As Cinco Brasas

Documento de design e plano de produção v1.0 | 14 de outubro de 2026

RPG de ação 2D para Android, com combate lateral em profundidade, hub evolutivo e seleção de masmorras pelo mapa.

Estado: proposta de projeto completa para orientar produção. Este documento não representa um jogo já implementado, assets finalizados ou APK compilado. Valores de combate, economia, duração e desempenho são alvos iniciais de prototipagem, sujeitos a testes reais.

Nome de trabalho: Dungeons Fires: As Cinco Brasas. A disponibilidade comercial do nome deverá ser verificada antes da publicação.

Referência solicitada: Golden Axe para linguagem visual de fantasia, silhuetas fortes e combate lateral de impacto; estrutura de dungeon crawler para loot, builds e retorno ao hub. Personagens, trama, mapas, interfaces, equipamentos, músicas e sprites terão identidade própria.

<!-- PAGE -->
## 01. Visão e limites do projeto

**Premissa jogável.** O jogador é um Portador de Brasa: alguém que sobreviveu ao apagamento das fogueiras sagradas e consegue transportar seu fogo dentro do próprio corpo. Partindo do Refúgio da Última Chama, escolhe expedições, derrota guardiões corrompidos, recupera materiais e reconstrói as estruturas que permitem avançar.

**Promessa.** Entrar em uma masmorra, vencer pelo posicionamento e pelo domínio do combate, voltar com uma peça valiosa e sentir o herói e o refúgio evoluírem. Cada chefe abre uma receita que altera a maneira de jogar.

| Decisão | Definição de projeto |
| --- | --- |
| Plataforma principal | Android, celular, tela horizontal e controle por toque |
| Engine | Godot 4.x estável, versão exata fixada ao iniciar a produção |
| Apresentação | Pixel art 2D detalhada, vista lateral com faixa de profundidade |
| Estrutura | Hub seguro, mapa de expedições, masmorras instanciadas |
| Modo inicial | Um jogador, offline, sem conta obrigatória |
| Sessão | Expedições de 8 a 15 minutos como alvo; saída segura no hub |
| Modelo comercial | Planejar experiência premium; preço e canais ficam para depois |

**Pilares.** Combate legível e satisfatório; arte coerente e expressiva; progresso perceptível no hub; loot com função; chefes que recompensam aprendizado; uso confortável no celular.

**Limites da primeira versão comercial.** Não incluir mundo aberto contínuo, PvP, multiplayer, construção livre, sobrevivência com fome, energia de entrada, gacha ou serviço diário obrigatório. Evitar misturar sistemas que exigem outras arquiteturas antes de consolidar o núcleo.

**Critério de qualidade.** Se o combate e a animação do primeiro herói não convencerem em uma única arena, a produção de novas masmorras deve esperar. O primeiro conteúdo aprovado vira referência para todo o restante.

<!-- PAGE -->
## 02. Lore: o mundo e a origem da crise

O continente de **Edrava** nasceu sobre os ossos de uma criatura celestial chamada **A Mãe da Aurora**. Quando ela morreu, cinco brasas permaneceram acesas em seu corpo. Povos diferentes construíram cidades em torno delas e aprenderam a usar seu calor para cultivar terras, forjar metais, preservar memórias e proteger os mortos.

As brasas nunca foram fontes infinitas. Elas se alimentavam dos nomes lembrados pelos vivos. Cada geração precisava contar histórias de quem havia partido, mantendo o fogo e a identidade do mundo. Esse pacto era chamado de **Vigília dos Nomes**.

Há trinta anos, uma guerra derrubou pontes, cidades e bibliotecas. Os reis entregaram a manutenção da Vigília a uma ordem de escribas, a **Custódia do Véu**. Seu fundador, **Severan**, descobriu que podia alimentar as brasas queimando lembranças diretamente. A ordem passou a cobrar memórias dos pobres como tributo: o rosto de uma mãe, um amor, a primeira viagem. O mundo ganhou calor, mas perdeu vínculos.

Severan tentou eliminar a perda para sempre. Uniu as cinco chamas em uma cerimônia que prometia trazer os mortos de volta. O fogo, alimentado por lembranças arrancadas, produziu o **Incêndio Branco**: uma chama fria que apaga nomes e deixa corpos movidos por hábitos vazios. Os mortos retornaram sem reconhecer ninguém. Os guardiões das brasas se tornaram carcereiros.

Agora, caminhos conhecidos levam a lugares esquecidos, sinos tocam sem mãos e cidades inteiras repetem o último dia antes da catástrofe. O silêncio se espalha de masmorra em masmorra.

No centro das ruínas, um pequeno forno continua aceso. Foi protegido por **Iria**, antiga copista da Custódia, que guarda um livro de nomes proibidos. Ao redor do forno cresceu o Refúgio da Última Chama. Ali, pessoas resgatadas constroem algo novo enquanto os Portadores procuram as cinco brasas.

**Tema central.** O que vale preservar quando manter tudo vivo significa impedir que algo novo exista? A vitória precisa devolver ao mundo o direito de lembrar e de mudar.

<!-- PAGE -->
## 03. História da campanha e personagens

**Prólogo.** Uma caravana chega ao refúgio perseguida por corpos sem nome. O jogador aprende movimento, ataque e esquiva defendendo o portão. Iria reconhece no sobrevivente uma brasa interior. A primeira expedição busca carvão e a ferramenta perdida do ferreiro.

| Ato | Conflito e revelação | Mudança no refúgio |
| --- | --- | --- |
| I: Os nomes roubados | Os saqueadores carregam listas de tributos; a catástrofe foi provocada | Forja recuperada e primeiros resgates |
| II: A memória enterrada | A Custódia apagou a história da guerra e os responsáveis | Arquivo aberto; mapa recebe rotas antigas |
| III: O preço da proteção | Uma cidade sacrificou seus mortos para se manter aquecida | Novos moradores e receitas de proteção |
| IV: O fogo aprisionado | Os guardiões resistem porque perderam quem deveriam proteger | Forja de relíquias e preparação final |
| V: A última Vigília | Severan mantém uma imagem da filha dentro da chama branca | Destino das brasas e epílogo do hub |

**Iria, a copista.** Mentor narrativo e cartógrafo do refúgio. Participou do sistema de tributos e quer reparar seus atos. Cada nome recuperado muda uma página do arquivo e libera uma conversa curta.

**Doran, o ferreiro.** Perdeu a lembrança do filho, mas conserva a ferramenta que construíram juntos. Coordena fabricação e aprimoramentos. Reconstruir sua forja permite que sua história apareça em objetos e gestos, além de diálogo.

**Sava, a boticária.** Cuida de sobreviventes e prepara consumíveis. Desconfia das brasas por ter visto os tributos de memória. Suas missões mostram as consequências para pessoas comuns.

**Oren, o vigia.** Organiza contratos e ensina o combate. Era soldado da Custódia; sua armadura possui marcas apagadas. Não acompanha as expedições na versão inicial.

**Severan, o Custodiante.** Antagonista que confunde preservação com prisão. A luta final desmonta sua proteção enquanto fragmentos do ritual revelam a filha que ele tenta recuperar. Ela não retorna como prêmio.

**Desfecho.** Libertar as brasas encerra o Incêndio Branco e leva os mortos ao descanso. O refúgio conserva uma pequena chama sustentada por lembranças compartilhadas livremente. Um epílogo mostra a praça cheia, as oficinas funcionando e nomes restaurados. Não há bifurcação de finais no escopo inicial.

**Forma de contar.** Falas de 2 a 4 linhas, cenas breves antes e depois de chefes, itens de lore opcionais e mudanças no cenário. Diálogos podem ser revistos no arquivo. A primeira visão de um chefe deve continuar forte mesmo ao pular a cena.

<!-- PAGE -->
## 04. Direção visual oficial proposta

**Linguagem.** Fantasia sombria aventureira, com heróis expressivos, arquitetura arruinada, monstruosidade e iluminação quente. A referência de Golden Axe será traduzida em proporções legíveis, cenários laterais, golpes amplos e teatralidade. Não usar sprites extraídos, nomes, composição de telas ou símbolos daquela franquia.

**Técnica.** Sprites desenhados e animados em pixel art; cenários em camadas; chão com profundidade aparente; sombras no ponto de contato; parallax discreto. A geometria jogável permanece 2D. Pixel art deve ter textura, volume e desenho consistente; não transformar a direção em personagens geométricos ou placeholders apresentados como arte final.

| Elemento | Regra de arte |
| --- | --- |
| Heróis | Silhueta distinta, rosto legível, roupas em camadas, armas proporcionais |
| Cenários | Primeiro plano, piso, estruturas, fundo distante e atmosfera |
| Luz | Ambientes frios contrastam com brasas âmbar e douradas |
| Inimigos | Papel de combate reconhecível pela pose, arma e silhueta |
| UI | Metal envelhecido, couro escuro, brasa contida e tipografia clara |
| VFX | Formas diferentes por elemento; área perigosa sempre delimitada |

**Cores de partida.** Carvão #171923; pergaminho #E7D7B5; brasa #E9853C; ouro #C9A35B; chama branca #C5E8F0. As cinco regiões acrescentam cores locais sem alterar o sistema visual da interface.

**Padrão de escala.** Base lógica proposta de 640 x 360, com personagens de aproximadamente 64 a 88 pixels de altura e chefes de 100 a 160. Uma primeira cena precisa validar a escala antes de encomendar assets. A UI é adaptada à resolução física para manter texto e toque confortáveis.

**Coesão.** Luz dominante vindo de cima e da esquerda, contornos seletivos, densidade de pixels semelhante e pés alinhados ao piso. Registrar paleta, escala, pivôs, origem da sombra e amostra de animação em um guia de arte.

**Mudanças de equipamento.** Armas mostram a família equipada. Cada herói terá quatro conjuntos visuais de armadura no lançamento, ligados a tiers, evitando criar uma animação inteira para toda combinação de peças. Capacetes muito complexos poderão permanecer apenas no retrato e no inventário, decisão explícita no guia.

**Gate visual.** Aprovar uma prancha com herói em idle/corrida/ataque, dois inimigos, um corredor, uma arena e HUD real. Imagens conceituais servem como referência; só capturas da execução serão chamadas de prints do jogo.

<!-- PAGE -->
## 05. Câmera, movimento e leitura espacial

O jogador anda para esquerda e direita e também sobe ou desce na faixa do chão. A câmera é lateral, como um beat 'em up. As masmorras usam corredores, praças e arenas conectadas; não são tabuleiros com visão aérea.

**Modelo espacial.** Separar a posição dos pés, que define colisão e alcance, da altura visual usada em saltos e efeitos. A profundidade da faixa do piso determina a ordem de desenho. A sombra permanece no chão, inclusive em um ataque com elevação visual.

**Movimento.** Analógico com intensidade variável: caminhada suave em baixa intensidade e corrida na intensidade alta, sem botão de sprint obrigatório. Mirar os pés nas colisões; impedir que decoração bloqueie caminhos sem leitura visual. O herói desacelera com resposta curta e sem sensação de deslizar.

**Combate em profundidade.** Um golpe só acerta quando o alvo está ao alcance horizontal e dentro da tolerância de profundidade daquela arma. A assistência de alinhamento aproxima levemente o golpe de um inimigo próximo, sem deslocar o herói através de obstáculos nem trocar de alvo repentinamente.

**Câmera.** Segue o jogador com antecipação discreta, limita-se aos limites da sala e ajusta o enquadramento em chefes. Zoom configurável em três níveis, com opção por gesto de pinça fora dos botões. Zoom máximo precisa manter ataques e sinais de perigo visíveis; chefes podem impor temporariamente um limite mais aberto, indicado ao jogador.

**Travessia.** Portas, escadas curtas e pontes são entradas contextuais. O MVP não exige plataforma ou botão de salto. Ataques aéreos podem ser animações de habilidades; isso reduz conflitos de controle no celular.

**Clareza.** Plataformas de fundo não parecem caminhos acessíveis. Portas utilizáveis recebem luz e interação. Objetos no primeiro plano ficam transparentes ao cobrir o herói. Saídas fechadas durante combate apresentam corrente e motivo visual.

**Teste crítico.** Dois inimigos sobrepostos precisam continuar selecionáveis e legíveis. Andar junto a paredes, atacar acima/abaixo de um alvo e entrar em uma porta devem funcionar sem depender de precisão de um pixel.

<!-- PAGE -->
## 06. Heróis, armas e identidade de combate

O lançamento prevê três Portadores com campanhas compartilhadas e falas próprias. O MVP usa apenas **Varek**, para validar animações e combate antes de multiplicar trabalho. Heróis adicionais são desbloqueados por resgates da campanha, sem compra obrigatória.

| Herói | Armas | Força | Fraqueza |
| --- | --- | --- | --- |
| Varek, Guardião da Forja | Espada e escudo; martelo de guerra | Interrupção, defesa ativa, combate próximo | Recuperação longa com martelo; alcance curto |
| Maela, Tecelã de Cinzas | Cajado; foco rúnico | Áreas de fogo, controle e reação elemental | Pouca resistência; mana exige gestão |
| Neris, Vigia dos Caminhos | Duas lâminas; arco | Mobilidade, sangramento e alcance | Baixa proteção; depende de posicionamento |

**Varek.** Sobreviveu ao apagar da forja porque segurou uma brasa com a mão nua. Seu escudo representa proteção escolhida, não obediência à Custódia. Espada oferece combo rápido e aparo; martelo troca velocidade por quebra de guarda.

**Maela.** Antiga aprendiz dos escribas, conhece os nomes que o fogo branco tenta apagar. Cajado favorece projéteis e áreas; foco permite conjuração próxima e marcas que explodem. Magia ofensiva é sua base, sem copiar ataques do guerreiro.

**Neris.** Mensageira entre comunidades isoladas, conserva mapas anotados em tecido. Lâminas favorecem ataques laterais e evasão; arco usa alvo assistido e projéteis que respeitam obstáculos. Não introduzir mira precisa de dois analógicos no MVP.

**Persistência.** Materiais, ouro, refúgio e campanha são compartilhados. Nível e talentos pertencem ao herói. Ao liberar Maela/Neris, entram no nível mínimo recomendado para a região atual, sem conceder equipamento de chefe gratuitamente. Evitar exigir repetir todo o início para experimentar outra classe.

**Habilidades.** Cada herói terá seis habilidades ativas escolhidas no hub; equipa duas, além de uma técnica suprema fixa por personagem. Não trocar habilidades em combate. Cada família de arma altera o combo básico e uma interação defensiva.

**Produção de animação.** Uma família aprovada é concluída antes da próxima. Para armas diferentes, reutilizar apenas o que mantém pose e peso convincentes; não alongar a mesma animação para fingir um martelo pesado.

<!-- PAGE -->
## 07. Sistema de combate e sensação dos golpes

**Fluxo básico.** Aproximar, alinhar-se, atacar, ler a preparação inimiga, esquivar ou defender e aproveitar a recuperação. Combo básico de três golpes com finalizador; segurando ataque, executar ataque carregado. Toques repetidos usam buffer curto para não perder comandos durante animações.

**Estados.** Idle, movimento, preparação, golpe ativo, recuperação, esquiva, defesa de habilidade, dano, queda, levantar, morte e interação. A máquina de estados define onde um comando pode interromper outro. Animação e dano usam a mesma linha temporal.

| Parâmetro de protótipo | Valor inicial | Regra de ajuste |
| --- | --- | --- |
| Simulação | Física a 60 Hz | Independente do FPS visual |
| Buffer de entrada | 120 ms | Validar responsividade e evitar ações acidentais |
| Invulnerabilidade da esquiva | 160 ms | Ajustar por sinais reais dos ataques |
| Recarga da esquiva | 0,8 s | Impedir invulnerabilidade contínua |
| Hit stop | 35 a 70 ms | Local; chefes e projéteis não quebram lógica |
| Aviso de ataque comum | 450 a 700 ms | Mais curto apenas após aprendizado |
| Aviso de ataque pesado | 800 a 1.200 ms | Forma no piso e animação coerentes |

**Recursos.** Vida para todos; mana apenas para Maela; recarga para habilidades de Varek e Neris. Não incluir barra universal de fôlego. A suprema carrega causando dano efetivo e se esvazia ao usar; atingir objetos não a carrega.

**Impacto.** Reação direcional, som específico da arma/material, breve pausa, faíscas ou partículas, recuo e efeito no alvo. Tremor de câmera é curto e desativável. Inimigos comuns podem cair; chefes possuem medidor de ruptura em vez de stun permanente.

**Ordem de resolução.** Checar invulnerabilidade, guarda, acerto, resistência, dano e reação. Um golpe possui ID de execução e só acerta o mesmo alvo uma vez, salvo habilidades declaradas como multihit. Impedir dano após morte e golpes duplicados em quedas de FPS.

**Fórmula inicial.** Dano = ataque da arma x multiplicador da ação x [100 / (100 + defesa)] x resistência elemental. Resistência elemental limitada entre 0,5 e 1,5 no balanceamento inicial. Crítico padrão de 1,5x; chance limitada a 40%. Arredondar somente no resultado final, mínimo 1 para acerto válido.

**Controle da multidão.** Limitar atacantes simultâneos a três inimigos comuns no perfil inicial. Os demais buscam posição ou anunciam entradas. Ataques fora da tela não causam dano sem indicação e oportunidade de resposta.

<!-- PAGE -->
## 08. Loop, regras de expedição e falha

**Loop de campanha.** Conversar no refúgio; selecionar destino no mapa; revisar loadout; entrar; atravessar salas; enfrentar chefe; escolher retornar; usar recompensas; abrir nova região. O jogador sempre sabe qual é sua próxima opção e o que falta para acessá-la.

**Dentro da masmorra.** Entrada segura, corredor de introdução, batalha com combinação de inimigos, evento ou sala opcional, miniboss quando houver, descanso anterior ao chefe e arena final. Usar 5 a 7 salas nas expedições comuns; encontros densos valem mais que corredores vazios.

**Vitalidade e cura.** Duas cargas de poção por expedição inicialmente, recarregadas ao iniciar uma nova expedição pelo hub. Sava aprimora eficácia e libera uma terceira carga. Não repor poções gratuitamente por suspender e reabrir o app. A sala de descanso restaura 25% da vida uma vez por visita naquela expedição, sem resetar habilidades supremas.

**Morte.** Perde o saque ainda não depositado e a recompensa pendente do chefe; conserva progresso permanente já registrado, desbloqueios e itens levados. Não destrói equipamentos. Repetir a masmorra pode recuperar o conteúdo por uma nova conclusão, sem mecânica de cadáver obrigatório.

**Retirada voluntária.** Na entrada e no descanso, permite retornar e depositar materiais comuns e ouro coletados. Receitas e peças de chefe só são recebidas após vitória. Fora desses pontos, abandonar equivale a perder o saque pendente; a tela apresenta a consequência antes de confirmar.

**Suspensão no celular.** Salvar estado em transições, loot e eventos importantes. Ao voltar, restaurar a expedição no estado consistente mais recente, sem duplicar recompensas. Não restaurar vida por reiniciar. Uma morte registra a falha antes de mostrar a tela de resultado.

**Vitória.** Um chefe concede a primeira receita garantida e um material exclusivo. Primeira conclusão muda o hub e o mapa; repetições dão materiais e loot, sem repetir automaticamente cutscenes.

**Dificuldades.** História reduz dano recebido e amplia janelas defensivas; Aventura é o padrão; Veterano é liberado após a campanha e acrescenta padrões, não apenas vida. Trocar dificuldade somente no hub, sem punição por jogar História.

**Evitar repetição obrigatória.** A primeira vitória de cada chefe deve fornecer o necessário para fabricar uma peça representativa. Farm adicional serve para especialização e melhorias, sem bloquear a campanha por sorte.

<!-- PAGE -->
## 09. Hub: Refúgio da Última Chama

O refúgio é uma área pequena e explorável. Todas as funções também aparecem em um menu de serviços, para que revisitar oficinas não consuma tempo com caminhadas obrigatórias. Há cinco estruturas aprimoráveis e um mercador sem nível.

| Estrutura | Nível 1 | Nível 2 | Nível 3 |
| --- | --- | --- | --- |
| Forja de Doran | Fabricar básico; +1 a +3 | Itens de chefe; +4 a +7 | Relíquias avançadas; +8 a +10 |
| Santuário das Brasas | Talentos iniciais | Segunda faixa de talentos | Especializações finais |
| Botica de Sava | Duas poções; cura 30% | Cura 40%; resistência | Terceira carga; cura 45% |
| Arquivo de Iria | Mapa e registro | Eventos e rotas laterais | Segredos e memória completa |
| Quartel de Oren | Tutorial e treino | Contratos de elites | Arena e contratos avançados |

**Evolução visual.** Nível 1 é uma estrutura improvisada; nível 2 usa telhado restaurado, ferramentas e moradores trabalhando; nível 3 recebe acabamento, iluminação própria e animações ambientais. A recuperação da praça acompanha a história e não exige um sexto sistema de construção.

**Aprimorar uma estrutura.** Exige um marco da campanha e materiais específicos. A tela mostra custo, benefício atual, benefício seguinte e aparência prevista. Ao confirmar, retirar recursos e aplicar upgrade em uma única transação; salvar; só então executar a animação de construção.

**Mercador.** Compra itens comuns e vende ingredientes de apoio; não oferece equipamentos de chefe nem materiais exclusivos. Atualizações de estoque dependem de atos concluídos, não do relógio real.

**Missões pessoais.** Doran recupera a ferramenta do filho; Sava resgata aprendizes; Oren encontra registros dos soldados; Iria restaura páginas do tributo. Cada arco possui três etapas e termina com uma recompensa pequena e uma transformação visual ou diálogo permanente.

**Treino.** Boneco de ataque, alvo móvel e simulação de sinais de perigo. Exibir dano médio e exemplos de esquiva sem exigir competir por DPS. Permite testar um item antes de investir recursos em upgrades.

**Resposta emocional.** Moradores retornam após resgates, oficinas passam a emitir sons e a música ganha instrumentos. O refúgio deve registrar a vitória de uma forma que o jogador perceba antes de abrir um menu.

<!-- PAGE -->
## 10. Mapa de expedições e desbloqueios

Mapa ilustrado de Edrava dividido em cinco regiões, com nós conectados por estradas. Não é um globo nem um mundo aberto. Cada região contém duas masmorras de preparação e uma de guardião. O jogador escolhe masmorras já liberadas e pode repetir anteriores.

| Região | Preparação A | Preparação B | Guardião |
| --- | --- | --- | --- |
| I: Fronteira de Fuligem | Mina dos Sinos | Bosque Carbonizado | Fortaleza da Brasa Partida |
| II: Várzea dos Nomes | Canais da Vigília | Ossuário Afogado | Catedral das Vozes Submersas |
| III: Coroa de Geada | Aldeia do Último Inverno | Galerias de Vidro | Bastilha do Sol Preso |
| IV: Deserto das Fornalhas | Caravana Petrificada | Fundição dos Exilados | Palácio de Ferro Rubro |
| V: Abismo Branco | Arquivo Sem Rostos | Ponte dos Ausentes | Coração do Véu |

**Grafo de campanha.** Concluir preparação A libera B; concluir B libera guardião; vencer guardião libera A da próxima região. Contratos opcionais e segredos retornam a nós anteriores, sem interromper o caminho principal. Arquivo de nível 2 revela rotas opcionais; o nível 1 sempre permite seguir a campanha.

**Estados dos nós.** Bloqueado, disponível, concluído e selecionado. Usar símbolo e texto além de cor. Um nó bloqueado informa o requisito exato: por exemplo, concluir Galerias de Vidro. Remover requisitos redundantes que forçam farm de nível.

**Painel da masmorra.** Arte local, breve objetivo, duração estimada, recomendação de nível, perigos, recompensa da primeira vitória, materiais disponíveis e progresso de segredos. Botão Preparar leva ao loadout; Entrar é a confirmação final.

**Níveis de referência.** Região I: 1-6; II: 7-12; III: 13-18; IV: 19-24; V: 25-30. O nível é recomendação; o desbloqueio depende da história. Rebalancear para que o caminho principal aproxime o herói da recomendação seguinte.

**Revisitas.** Dificuldades desbloqueadas, contratos e objetivos de receitas mantêm valor em áreas antigas. Não escalar silenciosamente a versão normal de uma masmorra: a melhoria do herói precisa ser percebida.

**Segredos.** Cada dungeon tem um pequeno desvio e uma pista ambiental. O mapa registra quantos segredos faltam sem entregar a solução. Concluir todos não é requisito para o final.

<!-- PAGE -->
## 11. Conteúdo das quinze masmorras

| Masmorra | Identidade jogável | Encontro principal |
| --- | --- | --- |
| Mina dos Sinos | Trilhos, minério, ruído que desperta inimigos | Capataz Rusk: martelo e carga anunciada |
| Bosque Carbonizado | Raízes, clareiras, fogo em faixas | Matriarca de Carvão: sementes e raízes |
| Fortaleza da Brasa Partida | Muralhas, portões e confronto de escudos | Garron, o Portão Vivo |
| Canais da Vigília | Passarelas, comportas e áreas inundadas | Barqueiro Sem Rosto: arrasto e anzol |
| Ossuário Afogado | Nichos, piso quebrado e ossos móveis | Zelador de Cal: escudo de ossos |
| Catedral das Vozes Submersas | Sinos e pilares que moldam ondas sonoras | Sereia de Cinzas |
| Aldeia do Último Inverno | Casas fechadas, vendaval e fogo protetor | Caçadora do Degelo: emboscada anunciada |
| Galerias de Vidro | Reflexos, cristais e feixes visíveis | Sentinela de Quartzo: ricochetes |
| Bastilha do Sol Preso | Fornos apagados e correntes de gelo | O Rei Enregelado |
| Caravana Petrificada | Carroças, tendas e tempestade de areia | Coletor de Tributos: golpes de corrente |
| Fundição dos Exilados | Esteiras lentas e vazamentos de metal | Mestra dos Cadinhos: zonas incandescentes |
| Palácio de Ferro Rubro | Salões mecânicos e portas térmicas | Colosso das Correntes |
| Arquivo Sem Rostos | Estantes, páginas e ecos de antigos encontros | Escriba Vazio: marcas e cópias ilusórias |
| Ponte dos Ausentes | Travessia quebrada, luzes e procissão | Vigia do Silêncio: cortes e deslocamento |
| Coração do Véu | Ritual, fragmentos de memórias e fogo branco | Severan, o Custodiante |

**Distinção de encontros.** As dez masmorras de preparação terminam em minibosses nomeados; cinco masmorras finais possuem chefes de duas fases. Os minibosses podem usar esqueletos de animação de elites, com comportamento próprio. Chefes finais recebem animações e arenas exclusivas.

**Formato de salas.** Cinco salas no MVP; cinco a sete no lançamento. Incluir uma sala opcional por dungeon. O orçamento comercial inicial é de 75 salas principais mais 15 desvios, reaproveitando kits de região com composição manual. Não prometer 90 conjuntos de arte independentes.

**Level design.** Cada masmorra apresenta uma mecânica, combina-a com inimigos e cobra domínio no encontro final. Não introduzir uma regra inédita no golpe fatal do chefe. Usar zonas seguras legíveis em incêndio, frio e inundação.

**Variabilidade.** Mapas de campanha desenhados manualmente; duas variantes leves de encontro e posições de baús por dungeon. Sem gerador procedural na primeira versão. A qualidade da primeira travessia tem prioridade sobre salas aleatórias.

<!-- PAGE -->
## 12. Chefes e recompensas exclusivas

| Chefe | Fase 1 | Fase 2 | Receita garantida |
| --- | --- | --- | --- |
| Garron, o Portão Vivo | Escudo frontal, investida e golpe de chão | Parte do escudo se rompe; ataques laterais | Marca do Portão: relíquia de proteção |
| Sereia de Cinzas | Ondas sonoras entre pilares | Pilares caem e mudam os corredores seguros | Eco das Marés: relíquia de controle |
| Rei Enregelado | Espada longa e linhas de gelo | Abre o forno central e alterna calor/frio | Coração do Inverno: relíquia de resistência |
| Colosso das Correntes | Braços presos, varredura e metal derramado | Solta uma corrente e muda o alcance | Elo Rubro: relíquia de ruptura |
| Severan | Memórias como escudos e projéteis brancos | Núcleo exposto; alterna padrões já aprendidos | Nome Restaurado: relíquia de conclusão |

**Garron em detalhe.** Três sinais distintos: erguer o escudo para investir; apoiar a arma antes de bater no piso; girar o ombro antes de varrer. Ataques pelas costas geram ruptura extra. Em 50% de vida, a defesa cai parcialmente e ele se torna móvel. A fase nova muda postura, som e arena, não apenas números.

**Escala de combate.** Chefes não ocupam tanto da tela que escondem os pés e o terreno. A câmera amplia a arena antes do primeiro ataque. A barra mostra fase e ruptura, sem cobrir a ação. Uma ruptura dá janela curta de dano e depois proteção temporária contra nova ruptura.

**Invocações.** No máximo dois auxiliares vivos simultaneamente no perfil inicial. Eles não aparecem em cima do jogador. A luta final pode usar ecos visuais, mas somente alvos relevantes ganham colisão e dano.

**Recompensa justa.** Primeira vitória dá receita e material suficiente para a relíquia do capítulo. Repetições dão material para aprimorar e fabricar variações. O tipo da recompensa principal é conhecido antes de entrar; não depender de rolagem para obter a identidade do chefe.

**Morte e reprise.** Retentar após falha não repete cutscene por padrão. Não alterar o padrão da luta a cada tentativa. A segunda fase deve ser reproduzível no modo de teste interno para depuração.

**Critério de aprovação.** Cada ataque pode ser evitado sem dano inevitável, sem combinação impossível de áreas e sem depender de equipamento específico. A sequência é simulada e depois testada por pessoas em tela real.

<!-- PAGE -->
## 13. Bestiário, IA e encontros

O plano comercial prevê **25 variantes de inimigos comuns**, cinco por região, derivadas de oito papéis de combate; **cinco elites regionais**; dez minibosses; cinco chefes. Variação deve incluir comportamento ou composição, além da cor.

| Papel | Comportamento | Resposta do jogador |
| --- | --- | --- |
| Saqueador | Aproxima e executa combo curto | Esquivar do finalizador ou interromper |
| Escudeiro | Protege frente; avança devagar | Flanquear ou usar quebra de guarda |
| Brutamontes | Golpes lentos com área | Ler o piso e punir recuperação |
| Atirador | Busca faixa livre e anuncia disparo | Mudar profundidade ou encurtar distância |
| Conjurador | Cria zona marcada | Sair da zona e interromper conjuração |
| Assaltante | Contorna e prepara salto curto | Perceber sinal e evitar cerco |
| Enxame | Unidades frágeis em quantidade limitada | Usar varredura e controle |
| Suporte | Protege aliado ou mantém totem | Priorizar suporte com oportunidade clara |

**IA.** Percepção, escolha de posição, preparação, execução, recuperação, reação e retorno. Gerenciador de encontro distribui vagas de ataque. Não perseguir indefinidamente fora da arena; não teleportar para recuperar posição. Rota simples pelo chão com obstáculos e pontos de acesso testados.

**Profundidade.** Atirador e conjurador escolhem alvo com base nos pés e na linha de visão. Inimigos deslocam-se para alinhar antes de golpear. Telegráficos não mudam de posição no último instante sem regra explícita.

**Elites.** Uma por região, com dois modificadores desenhados: por exemplo, escudeiro que deixa uma área de cinza após ruptura. Não gerar combinações aleatórias capazes de eliminar as janelas de resposta.

**Composição.** Começar com um papel isolado; combinar escudeiro com atirador; introduzir suporte; cobrar a prioridade no fim. Alvo inicial de quatro a seis inimigos ativos, com limite de oito em perfil alto após medição. Os limites menores não alteram quantidade total ou recompensas: entradas ocorrem em ondas.

**Reações.** Dano leve, pesado, ruptura, morte e status têm feedback distinto. Inimigos mortos deixam o combate antes de sua animação terminar. Corpos e partículas saem por pooling ou limpeza controlada.

<!-- PAGE -->
## 14. Progressão, talentos e builds

**Níveis.** 1 a 30. Cada nível concede aumento pequeno de vida/atributo principal e um ponto de talento do nível 2 ao 30, totalizando 29 pontos. O primeiro nível serve para aprender sem uma árvore obrigatória.

**Árvores.** Cada herói tem três ramos, seis nós por ramo. Cinco nós têm três ranks e um nó final tem um rank: 16 pontos para completar um ramo, 48 para todos. Com 29 pontos, o jogador combina especializações sem maximizar tudo. Não permitir comprar ranks fora de ordem.

| Herói | Ramo A | Ramo B | Ramo C |
| --- | --- | --- | --- |
| Varek | Bastilha: escudo e proteção | Ruptura: martelo e stagger | Fervor: combo e contra-ataque |
| Maela | Incêndio: dano contínuo | Sigilo: marcas e explosões | Vigília: barreira e controle |
| Neris | Lâmina: sangramento e flanco | Sentinela: arco e perfuração | Passagem: esquiva e mobilidade |

**Liberação.** Níveis 1, 4, 8, 12, 18 e 24 liberam uma habilidade ativa, total de seis por herói. A técnica suprema abre após o primeiro guardião. Talentos de segunda e terceira faixas também pedem níveis do Santuário, sem exigir reembolso ao aprimorar a estrutura.

**Reespecialização.** Gratuita no hub após concluir o tutorial de talentos. Sem penalidade para experimentar. Loadouts guardam equipamento, habilidades e talentos; três slots por herói no lançamento, um no MVP.

**Exemplos.** Varek Ruptura combina martelo, Elo Rubro e talentos que premiam ataque carregado. Maela Sigilo acumula marcas em alvos resistentes antes de detonar. Neris Sentinela usa arco, perfuração e reposicionamento. Cada uma muda decisões, não só um percentual de dano.

**Itens versus nível.** A maior mudança de estilo vem de família de arma, habilidades e efeito da relíquia. Nível e upgrade sustentam a curva. Evitar um item que torne todas as outras opções obsoletas.

**Status.** Queimadura causa dano limitado; sangramento favorece ataques sucessivos; lentidão não imobiliza chefes; vulnerabilidade aumenta ruptura. Uma regra de duração e teto por status evita acumulação ilimitada. Inimigos resistentes exibem ícone e feedback.

**Balanceamento.** Medir tempo para eliminar um inimigo, duração de chefe, dano recebido por encontro, uso de poções e opções escolhidas. Objetivo inicial: chefe normal de 90 a 180 segundos, sem exigir farm e sem alongar a vida para esconder poucos padrões.

<!-- PAGE -->
## 15. Loot, inventário e fabricação

**Slots equipáveis.** Arma, cabeça, corpo, botas, talismã e relíquia: seis slots. Escudo faz parte da família espada/escudo e não cria um sétimo slot. Relíquias são universais; arma respeita o herói.

| Catálogo de lançamento | Quantidade | Organização |
| --- | --- | --- |
| Armas base | 48 | Seis famílias, oito modelos por família |
| Peças de armadura | 36 | Doze cabeças, doze corpos, doze botas |
| Talismãs | 24 | Mobilidade, recursos, defesa e combos |
| Relíquias | 12 | Cinco de chefes e sete de exploração/missões |
| Habilidades ativas | 18 | Seis por herói; duas equipadas |
| Técnicas supremas | 3 | Uma por herói |

**Raridades.** Comum, raro, épico e lendário. Texto e ícone além da cor. Comum é funcional; raro especializa um atributo; épico favorece um estilo; lendário altera uma interação com limite claro. Poucos efeitos lendários são melhores que muitos bônus sem função.

**Geração.** Item tem definição base por ID e instância com raridade, upgrade e até dois afixos. Bosses e missões dão receitas fixas; drops comuns usam tabelas por masmorra. Sorte afeta variedade, não o acesso aos marcos da campanha.

**Upgrade.** +0 a +10, sem falha ou destruição. Custos aumentam por faixa, limitados pelo nível da forja. Afixos não mudam ao aprimorar. No MVP, +0 a +3 e sem rolagem de afixos.

**Fabricação.** Selecionar receita, ver compatibilidade e comparação, checar recursos, confirmar e receber. Primeira receita de chefe inclui escolha de variação compatível quando aplicável. Material único nunca é vendido automaticamente.

**Desmontagem.** Devolve materiais comuns definidos, sem gerar o material exclusivo de chefe e sem lucro sobre fabricar/desmontar. Itens equipados e favoritos protegidos. Desmontagem em lote exibe resultado total antes de confirmar.

**Inventário.** Abas Mochila, Equipamentos, Fabricação e Coleção. Sessenta espaços iniciais para equipamentos; materiais em pilhas separadas não consomem esses espaços. Se lotar, loot vai para baú de excedentes no hub; nunca desaparece silenciosamente. Comparação mostra alteração de atributos e efeito especial, não apenas score.

**Receitas.** Listar origem, custo, recurso disponível e requisito da oficina. Coleção registra modelos descobertos, lore e local de obtenção. Não exigir coletar toda raridade de toda arma para completar a campanha.

<!-- PAGE -->
## 16. Economia e exemplo de progressão

**Recursos.** Ouro paga serviços; minério e tecido sustentam itens comuns; resina e cristais atendem afixos e proteção; cinco materiais de chefe atendem suas receitas; Cinza Viva é recompensa de missões/marcos para estruturas. Não criar moedas adicionais para cada interface.

**Regra de oferta.** Fontes e gastos são previsíveis. Ouro vem de encontros, baús e contratos; materiais comuns têm origem indicada no mapa. Recursos de hub vêm principalmente de primeiras vitórias e resgates, garantindo que completar a campanha permita evoluir as estruturas necessárias.

| Exemplo do começo | Entrada/custo inicial | Intenção |
| --- | --- | --- |
| Mina dos Sinos concluída | 120 ouro e 10 minério garantidos | Financiar primeira melhoria |
| Espada +1 | 40 ouro e 4 minério | Melhoria imediata após tutorial |
| Espada +2 | 65 ouro e 6 minério | Escolha entre melhorar e fabricar |
| Relíquia do Portão | 100 ouro e 1 núcleo garantido | Recompensa utilizável após o chefe |
| Forja nível 2 | 250 ouro, 20 minério e 1 Cinza Viva | Marco após região I, sem sorte |

**Cobertura do primeiro ato.** As três masmorras entregam no mínimo 420 ouro, 34 minério, um núcleo e uma Cinza Viva no total. Comprar espada +1, relíquia e Forja 2 custa 390 ouro e 24 minério; a rota básica permanece possível sem vendas ou farm. Essas quantidades são um ponto de partida, não economia já validada.

**Distribuição.** Materiais comuns são 70% da oferta planejada; itens/equipamentos 20%; consumíveis/colecionáveis 10%. Cada tabela respeita seu próprio limite. Não somar probabilidades de sistemas diferentes como se fossem uma única rolagem.

**Evitar abuso.** Preço de venda abaixo do custo de fabricação; compras/vendas e upgrades atômicos; recompensas de primeira conclusão concedidas uma única vez; desmontagem não devolve tudo. Contratos repetíveis não dão infinitamente recursos de marco.

**Sem desgaste.** Não incluir durabilidade ou taxa de reparo na primeira versão. Evita cobrar manutenção pelo simples ato de jogar e simplifica o retorno ao hub.

**Pós-campanha.** Veterano adiciona contratos regionais, melhoria das relíquias e busca de builds. Não elevar o cap de nível nem inventar uma moeda de endgame antes de provar interesse real no loop.

<!-- PAGE -->
## 17. Interface mobile e acessibilidade

**Tela de jogo.** Vida no alto à esquerda; mana ou recurso pertinente abaixo; objetivo curto no alto ao centro; minimapa simplificado à direita. Na base, analógico à esquerda com margem interna confortável; ataque grande e esquiva ao lado à direita; duas habilidades acima e suprema em posição distinta. Poção próxima à vida, movível no editor de controles.

**Toque.** Alvo mínimo de 48 dp, áreas generosas, distância entre botões e suporte a ao menos três toques simultâneos. Ajustar posição, tamanho e opacidade dos controles; salvar por aparelho. Não colocar analógico na extremidade nem cobrir o herói com painel permanente.

| Tela | Conteúdo essencial | Saída clara |
| --- | --- | --- |
| Inicial | Continuar, novo jogo, opções | Voltar ao sistema |
| Seleção de herói | Papel, armas e desbloqueio | Voltar ao menu |
| Hub | Serviços, missão e mapa | Salvar e sair |
| Mapa | Nós e detalhes da expedição | Voltar ao hub |
| Preparação | Equipamento, skills e dificuldade | Entrar ou cancelar |
| Inventário/forja | Abas, comparação, custo e efeito | X e botão voltar do Android |
| Gameplay | Controles, sinais e pausa | Menu de pausa |
| Resultado | Saque, objetivo e desbloqueios | Retornar ou repetir |

**Menus.** Inventário e pausa interrompem a simulação no modo solo. Modais têm botão X, gesto/tecla de voltar e foco correto. Confirmar apenas ações com perda, como desmontar item ou abandonar expedição; equipar e ler não exigem confirmação.

**Mapa no celular.** Pinça e arrasto com limites; toque simples seleciona; entrar exige botão separado. Destinos bloqueados explicam o requisito. A região disponível aparece centralizada ao abrir.

**Acessibilidade.** Tamanho de texto em três escalas, tremor e flashes desligáveis, legenda, volume separado, alto contraste de perigos, raridade por símbolo, dano numérico opcional e assistência de mira ajustável. Não depender apenas de vermelho/verde para sinalizar perigo.

**Dispositivos.** Respeitar safe areas e diferentes proporções de tela. Base lógica mantém visão útil; barras decorativas só quando necessário. Validar botões nas proporções 16:9, 19.5:9 e 20:9, sem esticar sprites.

**Tutorial.** Ensina uma ação por vez em situações reais. Controles só aparecem quando o jogador recebe controle; cutscenes escondem botões e não aceitam ataques acumulados para o retorno.

<!-- PAGE -->
## 18. Áudio, animações e apresentação

**Música.** Hub com cordas suaves, madeira e tema de brasa; instrumentos entram conforme estruturas são restauradas. Masmorras possuem textura regional; combate aumenta intensidade sem reiniciar a faixa a cada inimigo. Chefes têm motivo próprio e transição de fase sincronizada.

**Som.** Passos discretos por superfície, sem volume cansativo; espada corta, escudo reverbera, martelo tem grave curto, arco tem tensão e magia tem assinatura própria. Limitar sons simultâneos e priorizar aviso de perigo sobre moedas e decoração.

**Mixagem.** Barras Música, Efeitos e Interface. Avisos de combate têm prioridade; usar compressão/limite para evitar picos desconfortáveis. Ambientação não deve competir com fala ou sinais de ataques. Dublagem completa fica fora do escopo inicial; falas com legendas e vocalizações curtas.

| Animação por família de arma | Faixa inicial de frames | Finalidade |
| --- | --- | --- |
| Idle | 8-12 | Respiração e peso sem oscilação exagerada |
| Caminhada/corrida | 8-12 cada | Pés coerentes, sem deslizar |
| Combo | 6-10 por golpe | Preparação, contato e recuperação |
| Carregado | 10-14 | Peso e silhueta distinguíveis |
| Esquiva e dano | 6-10 cada | Resposta clara e curta |
| Habilidades/suprema | 10-18 cada | Identidade e impacto |

**Orientação.** Base de animação voltada para direita/esquerda com espelhamento quando a arte permitir. Subir/descer no chão muda deslocamento e sombra, mantendo a convenção lateral. Partes assimétricas e escrita não podem ser espelhadas sem correção.

**Armas e armaduras.** Usar pontos de encaixe e camadas somente após testar se o resultado mantém qualidade. Cabeça, tronco e mãos precisam permanecer unidos; arma não flutua nem aponta para trás no golpe. A animação aprovada de uma família determina suas hitboxes.

**VFX.** Um conjunto por família de arma, status e chefe. Fogo normal é âmbar; fogo branco é pálido com contorno frio. A intensidade de partículas pode cair no perfil baixo, preservando área e duração dos sinais.

**Gate de movimento.** Verificar idle, correr, mudar direção, parar, atacar, receber dano e retornar ao movimento no cenário real. Contato dos pés, pivôs e arma são critérios obrigatórios; quantidade de frames isoladamente não prova qualidade.

<!-- PAGE -->
## 19. Arquitetura Godot e dados de conteúdo

**Princípio.** Separar dados, simulação, apresentação e interface. Masmorras referenciam conteúdo por IDs; não criar atributos improvisados dentro de cada cena. A versão da engine e os templates Android ficam registrados no repositório.

| Módulo | Responsabilidade |
| --- | --- |
| GameFlow | Menu, hub, mapa, expedição e resultado |
| PlayerController/CombatState | Entrada, movimento, estados e comandos |
| CombatResolver | Hitboxes, dano, status, ruptura e eventos |
| EnemyController/EncounterDirector | IA, vagas de ataque e ondas |
| DungeonRunner | Salas, transições, descanso, objetivo e chefe |
| Inventory/Crafting/HubProgression | Instâncias, receitas, recursos e estruturas |
| ContentDB | Definições validadas e referências por ID |
| SaveManager | Persistência, recuperação e migrações |
| AudioDirector/VFXPool | Mixagem, prioridade e efeitos reutilizados |
| MobileUI | HUD, menus, acessibilidade e layout |

**Estrutura de arquivos.** scenes/hub, scenes/dungeons, scenes/actors, scenes/ui; scripts/combat, scripts/progression, scripts/save; data/heroes, data/items, data/recipes, data/enemies, data/dungeons, data/dialogues; art, audio, tests e docs. Não colocar sistemas de domínio em um único script central.

**IDs.** HERO_VAREK, REGION_FULIGEM, DUN_MINA_SINOS, BOSS_GARRON, ITEM_MARCA_PORTAO, RECIPE_MARCA_PORTAO, QUEST_FORJA_01. Catálogo registra nome, versão, estado de aprovação, fonte/licença, arquivos, escala, pivô e relações.

**Dados.** Definições por Godot Resource ou JSON com schema validado; escolher uma representação principal antes da produção. Instância de equipamento contém instance_id, definition_id, afixos e upgrade. Saves armazenam IDs e valores mutáveis; não caminhos de cena como identidade.

**Eventos.** Acerto, morte, loot, conclusão e upgrade geram eventos tipados. UI reage aos eventos, sem conceder recompensa diretamente. Transações são idempotentes para impedir dupla execução ao reabrir uma tela.

**Renderização.** Sprites ordenados pela posição dos pés e efeitos em camadas explícitas. Testar nearest sampling, escala e câmera para não borrar ou tremer pixel art. Escolher renderer e ajustes Android após medição em aparelho, sem depender de efeitos caros para leitura.

<!-- PAGE -->
## 20. Salvamento, desempenho e Android

**Save versionado.** Guardar heróis, equipamentos, recursos, upgrades do hub, missões, mapa, opções e expedição pendente. Escrever em temporário, validar e substituir arquivo principal mantendo backup. Não restaurar um backup de recompensa de forma que duplique itens.

**Expedição.** Snapshot inclui dungeon/sala, vida, poções, inimigos vivos, loot pendente, objetos consumidos, seed de encontros e checkpoints narrativos. Vida e resultados importantes são persistidos em marcos definidos. Se salvar em um momento inconsistente, retomar no último estado completo, sem premiar o intervalo perdido.

**Interrupções.** Pausar ao perder foco; salvar estado consistente; respeitar ligação, bloqueio de tela e app encerrado pelo Android. Áudio para em segundo plano. Ao voltar, mostrar breve contagem antes de liberar combate. Exportação/importação de save é futura, não requisito de login.

| Alvo de engenharia | Meta inicial | Como validar |
| --- | --- | --- |
| FPS | 60 em aparelho intermediário; perfil 30 para fracos | Medir lutas, hub e pior arena |
| Frame a 60 FPS | Até 16,7 ms na maioria dos frames | Registrar CPU/GPU e picos |
| Memória residente | Orçamento inicial até 350 MB | Medir após revisitas e 30 minutos |
| Carregamento de dungeon | Meta de até 4 s após assets locais | Medir em aparelhos de referência |
| Pacote instalado/download | Acompanhar desde o MVP | Limitar áudio/texturas; meta não é promessa |
| Toque | Sem perda ao mover e atacar/esquivar | Testar três toques e troca de foco |

**Otimização.** Carregar uma região por vez, usar atlas por conjunto relevante, pooling de VFX, limite de vozes, colisores simples e partículas controladas. Perfil baixo reduz decoração e partículas, preservando mecânicas e sinais de perigo.

**Build.** Exportar APK de teste e AAB de publicação com mesmo package e política de assinatura consistente. Versionar número/nome da versão; proteger keystore e segredos fora do repositório. Dependências, SDK e requisitos de loja serão verificados na implementação, quando atuais.

**Instalação.** Validar assinatura, integridade e atualização sobre versão anterior. APK que apenas exportou não é tratado como aprovado: precisa abrir, iniciar, jogar, salvar, retomar e voltar ao hub em Android real.

<!-- PAGE -->
## 21. Escopo: protótipo, MVP e lançamento

| Conteúdo | Fatia vertical | MVP público de teste | Lançamento 1.0 |
| --- | --- | --- | --- |
| Heróis | Varek, espada/escudo | Varek, duas famílias | Três heróis, seis famílias |
| Hub | Forja e mapa funcionais | Cinco estruturas, níveis 1-2 | Cinco estruturas, níveis 1-3 |
| Masmorras | Mina dos Sinos, cinco salas | Três da região I | Quinze em cinco regiões |
| Inimigos | Três comuns e Rusk | Cinco comuns, elite, dois minis, Garron | 25 comuns, cinco elites, dez minis, cinco bosses |
| Itens | Seis itens e um upgrade | 12 armas, 12 armaduras, seis talismãs, duas relíquias | 48/36/24/12, respectivamente |
| Progressão | Níveis 1-3 e dois talentos | Níveis 1-6; cinco pontos de talento | Níveis 1-30; 29 pontos na campanha |
| História | Prólogo e retorno à forja | Ato I completo | Cinco atos e epílogo |
| Android | APK interno | APK de avaliação após gates | APK validado; AAB para publicação |

**Talentos no MVP.** A campanha concede cinco pontos pelos níveis 2-6. Ferramentas internas podem montar builds de teste sem alterar a regra do save público.

**Marco principal.** A fatia vertical precisa incluir o loop inteiro: hub, mapa, loadout, combate, loot, retorno, fabricação, melhoria visível e save. Uma arena isolada sem retorno e progressão não atende a esse marco.

**Conteúdo que pode ser cortado.** Arena opcional, loadouts extras, desafios Veterano e variantes de eventos. Cortar primeiro essas expansões se a produção ficar cara. Não cortar qualidade do combate, funcionamento offline, save ou identidade visual.

**Fora da primeira versão.** Multiplayer, monetização por anúncios, servidores, eventos em calendário real, procedural, dublagem completa e árvore de finais. Podem ser avaliados em outro documento após o lançamento, sem aparecer como promessa no menu.

**Meta de campanha.** Cinco a oito horas na primeira conclusão, considerando tentativas, diálogos e evolução; expedições de 8-15 minutos. O percurso perfeito das quinze masmorras será mais curto. Medir tempo real antes de anunciar duração comercial.

<!-- PAGE -->
## 22. Plano de produção e dependências

As etapas abaixo são uma sequência de entregas, não trabalho agendado nem promessa de prazo. Uma estimativa de calendário só deverá ser feita depois de medir a primeira família de animações e a primeira masmorra em Android.

| Etapa | Entregável verificável | Gate para avançar |
| --- | --- | --- |
| P0: Pré-produção | GDD, guia de arte, catálogos e orçamento de assets | Escopo, controles e padrão visual definidos |
| P1: Combate | Varek, arena, três inimigos, dano e esquiva | Golpes legíveis e toque responsivo |
| P2: Arte em jogo | Herói final, kit da mina, HUD e áudio | Capturas reais e animações aprovadas |
| P3: Fatia vertical | Hub-mapa-Mina-loot-forja-save | Loop completo e recuperação de save |
| P4: MVP | Região I, hub 1-2 e Garron | APK instalado; campanha curta sem bloqueios |
| P5: Sistemas completos | Talentos, afixos, relíquias e heróis restantes | Builds distintas e catalogação correta |
| P6: Campanha | Regiões II-V, história, chefes e epílogo | Campanha completa, balanceada e sem placeholders |
| P7: Polimento | Acessibilidade, perfis e correções | Matriz Android e estabilidade aprovadas |
| P8: Publicação | Pacote final, materiais e documentação | Assinatura, licenças e build revisadas |

**Dependências.** A geometria dos personagens e os pivôs antecedem hitboxes finais; o combate antecede chefes; inventário e transações antecedem economia; save antecede teste de retomada; o kit de uma região antecede suas salas; desempenho em aparelho antecede aumentar densidade.

**Capacidade artística.** Roteiro/level design, programação Godot, pixel art/animação, áudio e QA são funções necessárias. Podem ser exercidas pela mesma pessoa em produção independente, mas isso aumenta o calendário. Não multiplicar conteúdo por agentes ou geradores sem aprovação de arte e integração.

**Ritmo de versões.** v0.1 combate; v0.2 arte integrada; v0.3 fatia vertical; v0.4 MVP; v0.5 progressão e catálogo; v0.6 segundo herói; v0.7 terceiro; v0.8 campanha completa; v0.9 polimento; v1.0 candidata à publicação. Cada versão precisa de objetivo e relatório verificável.

**Gestão de alterações.** Mudança visual ou sistema grande vira decisão registrada, com efeito sobre prazo e assets. O guia aprovado não é substituído silenciosamente por outra estética. Manter uma lista separada de ideias futuras.

<!-- PAGE -->
## 23. Backlog, QA e definição de pronto

| Prioridade | Trabalho | Aceitação |
| --- | --- | --- |
| P0 | Movimento e profundidade | Pés, colisões e sorting corretos |
| P0 | Combo, esquiva e dano | Sem hits duplicados; comandos consistentes |
| P0 | Mobile multitouch | Mover e usar duas ações sem perder entrada |
| P0 | Hub-mapa-dungeon | Entrar, vencer/retirar e retornar sem travar |
| P0 | Save e transações | Upgrade/loot não duplicam ao reiniciar |
| P0 | Primeiro kit visual | Herói e cenário finais coerentes em execução |
| P1 | Talentos, receitas e comparação | Benefícios e custos correspondem aos dados |
| P1 | Chefes e campanha | Padrões evitáveis; todos os desbloqueios funcionam |
| P1 | Acessibilidade e perfil baixo | Gameplay legível e controles confortáveis |
| P2 | Arena, loadouts e Veterano | Só após estabilidade da campanha |

**Testes automatizados.** Fórmula de dano/status e limites; referência de todos os IDs; compra/upgrade/desmontagem sem saldo negativo; primeira recompensa única; save com migrações e interrupção de escrita; avanço do grafo até final; duração de hitbox e hit único; snapshot consistente da expedição.

**Testes no engine.** Parser, imports, cenas carregando, nós obrigatórios, mudanças de estado, chefes nas duas fases e execução das transições. Ferramenta de QA inicia salas, habilidades e builds conhecidas, sem modificar o modo público.

**Testes em aparelho.** Primeiro início, novo save, continuar, toque com três dedos, câmera, menus/X/voltar, suspensão por ligação, encerramento forçado, reabertura, morte, inventário cheio, upgrade, save corrompido e atualização sobre APK anterior. Medir 30 minutos de jogo e observar aquecimento, memória e estabilidade.

**Varredura antes de entrega.** Zero erro de parser/import, referências resolvidas, nenhum placeholder apresentado como final, pacote sem temporários/segredos, licenças anexadas, assinatura e integridade verificadas. ZIP de fonte, se solicitado, só após auditoria e CRC aprovado.

**Definição de pronto.** Uma função está concluída quando funciona no fluxo completo, seus dados persistem, a UI informa resultados corretos e os testes pertinentes passam. Exportação não equivale a teste; render real não equivale a APK aprovado; concept art não equivale a asset integrado.

<!-- PAGE -->
## 24. Riscos, direitos e próximas entregas

| Risco | Sinal | Resposta de produção |
| --- | --- | --- |
| Animações demais | Família de arma ainda incompleta ao abrir outra | Concluir Varek e medir esforço antes de expandir |
| Visual inconsistente | Assets com escala/luz diferentes | Catálogo, guia e gate visual por lote |
| Combate confuso | Jogador toma dano sem entender | Reduzir simultaneidade e melhorar sinais |
| Farm obrigatório | Campanha exige repetir por falta de material | Garantias de primeira vitória e ajuste de custos |
| Save frágil | Reiniciar altera recompensa ou duplica item | Transações, IDs de recompensa e backup testado |
| Android pesado | Picos em chefes ou aquecimento | Perfil baixo, pooling e kit carregado por região |
| Escopo crescente | Sistemas futuros entram antes do MVP | Registrar ideias e preservar os gates |

**Direitos.** Produzir arte original ou usar assets com licença compatível com redistribuição dentro do jogo. Guardar fonte, autor, licença, comprovante e atribuição. Não usar rips de Golden Axe nem músicas da franquia. Verificar fontes tipográficas e efeitos de som também. A consulta de licenças será feita antes de incorporar qualquer asset externo; este documento não certifica direitos de materiais ainda não selecionados.

**Catálogo mínimo de produção.** Um guia de arte; três fichas de herói; seis fichas de família de arma; cinco kits regionais; 25 comuns; cinco elites; dez minis; cinco chefes; 120 definições de equipamentos; 18 skills e três supremas; cinco estruturas em três estados; quinze fichas de dungeon; diálogos e missões com IDs. O número 120 corresponde a 48 armas + 36 armaduras + 24 talismãs + 12 relíquias.

**Primeira entrega de implementação.** Projeto Godot com estrutura modular, controle mobile, Varek com espada/escudo, cenário da Mina dos Sinos, três inimigos, Rusk, Forja nível 1, mapa com um destino e loop completo de recompensa/save. Incluir arte final da fatia, captura real da execução e relatório de validação. APK apenas após exportação e testes disponíveis serem concluídos e seus limites descritos.

**Critério para iniciar conteúdo em escala.** Aprovar a sensação de movimento, golpe e corrida; validar proporção do herói na tela; confirmar legibilidade da profundidade; demonstrar upgrade com mudança de atributo; salvar e retomar; concluir expedição no aparelho.

**Estado ao fim deste planejamento.** Lore, identidade, campanha, conteúdo, sistemas, arquitetura e fases de produção definidos como proposta v1.0. Próximo marco é P0/P1: catálogo inicial e protótipo real de combate. Não há jogo implementado ou build instalável nesta entrega.

<!-- PAGE -->
## A1. Habilidades: catálogo inicial

As seis habilidades são liberadas, na ordem abaixo, nos níveis 1, 4, 8, 12, 18 e 24. Números de dano, duração e recarga serão registrados nas definições após testar o primeiro combo. As funções abaixo delimitam o conteúdo, evitando habilidades duplicadas.

| Herói | Habilidade | Função e limite |
| --- | --- | --- |
| Varek | Investida da Forja | Avança em linha; interrompe comum, respeita obstáculos |
| Varek | Guarda Ardente | Proteção curta; contra-ataque se recebe golpe frontal |
| Varek | Fenda de Ferro | Golpe de chão que aumenta ruptura em faixa curta |
| Varek | Grito da Vigília | Enfraquece ataque de inimigos próximos por tempo limitado |
| Varek | Retorno da Brasa | Contra-ataque forte disponível após esquiva bem-sucedida |
| Varek | Muralha Viva | Defesa em área curta; perde força enquanto Varek se move |
| Maela | Dardo de Cinza | Projétil rápido; custo baixo e sem atravessar parede |
| Maela | Círculo de Nomes | Área de queimadura com limite de alvos ativos |
| Maela | Selo Partido | Marca um alvo; nova ativação detona a marca |
| Maela | Véu Âmbar | Barreira temporária que absorve quantidade limitada |
| Maela | Corrente da Memória | Salta entre até três alvos próximos, com dano decrescente |
| Maela | Vigília Incandescente | Canalização curta; interrompível, risco com retorno alto |
| Neris | Corte de Passagem | Deslocamento com ataque; não atravessa barreiras |
| Neris | Marca da Caça | Prioriza alvo e aumenta eficácia de flanco por tempo limitado |
| Neris | Disparo Perfurante | Linha de projétil para arco; corte em linha para lâminas |
| Neris | Laço de Cinza | Armadilha com atraso visível e lentidão; sem prender chefe |
| Neris | Passo do Ausente | Reposiciona e deixa distração breve, sem invisibilidade contínua |
| Neris | Chuva de Estilhaços | Área marcada com flechas ou lâminas conforme arma |

**Supremas.** Varek: Forja do Amanhã, golpe pesado que abre janela de ruptura; Maela: Aurora Recuperada, explosão controlada seguida de campo breve; Neris: Caminho das Centelhas, sequência rápida sobre alvos válidos em alcance. Invulnerabilidade, se usada na execução, termina com a animação e não pode ser renovada por reset de sala.

**Compatibilidade.** Se uma habilidade precisa adaptar-se à família, definir as duas versões no mesmo registro, com leitura equivalente. Não mostrar um arco na mão de Neris quando ela está equipada com lâminas. Varek mantém efeito de guarda com martelo por postura defensiva própria, sem escudo flutuante.

<!-- PAGE -->
## A2. Receitas, materiais e valores de partida

| Guardião | Material único | Efeito da relíquia de capítulo |
| --- | --- | --- |
| Garron | Núcleo do Portão | Após defesa válida, próximo golpe gera ruptura extra |
| Sereia | Pérola de Eco | Primeira skill usada após esquiva aplica lentidão breve |
| Rei Enregelado | Fragmento Solar | Reduz efeito de frio e concede proteção após sair de perigo |
| Colosso | Elo de Sangue-Ferro | Ataque carregado aumenta ruptura com recarga interna |
| Severan | Letra Incandescente | Benefício de recurso após vencer um elite; sem loop infinito |

**Equipamentos iniciais.** Espada de Vigília (combo equilibrado); Martelo do Trilho (ruptura); Cota de Fuligem (proteção); Botas do Mineiro (mobilidade em piso pesado); Talismã do Sino (pequena recuperação de recurso após interrupção). São cinco fichas de partida, ampliadas pelos modelos previstos no catálogo.

**Receita de exemplo.** Espada de Vigília: 60 ouro, 8 minério e 2 tecido, Forja nível 1. Marca do Portão: 100 ouro e 1 Núcleo do Portão, Forja nível 2. Fabricação dá uma instância +0. Núcleo e receita são garantidos na primeira vitória de Garron; minério e ouro podem ser consultados no mapa.

**Sequência de desbloqueio.** Ao vencer Garron, liberar primeiro Forja 2; permitir fabricar a relíquia imediatamente após o upgrade. A tela de resultado mostra essa sequência. Para as demais estruturas, nível 2 depende de concluir região I e sua missão de introdução; nível 3 depende de concluir região III. As melhorias exigidas no caminho principal recebem recursos suficientes das primeiras conclusões.

**Experiência inicial.** Custo para passar de nível L para L+1: 100 + 25 x (L-1) + 5 x (L-1)^2, até L=29. Compartilhar XP de encontro dentro da campanha solo não é necessário. Calibrar recompensa de dungeon para atingir a faixa recomendada da região seguinte sem depender de matar inimigos infinitamente gerados.

**Tabela de loot de referência.** Um baú comum da Mina dos Sinos tem uma rolagem: 70% materiais, 20% equipamento comum/raro e 10% consumível. Ouro de encontro é concedido separadamente. O baú de chefe contém recompensa garantida mais uma rolagem independente. Registrar a seed e os resultados já consumidos para que retomar o app não gere outro saque.

**Custos completos.** As tabelas de ouro, XP, upgrades, ofícios e drops de todas as regiões serão arquivos de dados durante a produção. O GDD define fórmulas e exemplos auditáveis; não finge que os 120 equipamentos já possuem balanceamento aprovado.

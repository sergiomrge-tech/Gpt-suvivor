# Checkpoint — 13/10/2026 — v0.8.0 completa no código

Branch `feat/cave-relics-v081`, derivada de `feat/explorable-caves-v08` aprovada no CI. Cenários das duas cavernas mantidos e expandidos com `SurvivorCavePuzzles`: quatro selos e dois relicários modelados diretamente no Godot, interação com botão Explorar após aproximação, ativação por contato, recompensa única com 1 cristal por caverna, minimapa e Diário com progresso. A descoberta `east_vault` desbloqueia estação de aprimoramento nível 2, modelada em 3D, fabricada próxima da bancada com recursos reais. Machado e picareta reforçados têm novos modelos 3D nas mãos do jogador, receitas e equipamentos persistidos, custo efetivo apenas ao contato e rendimento 12 madeiras / 9 pedras. `SAVE_VERSION=3` mantida sem quebrar outros conteúdos.

A validação native Godot 4.6.1 deve manter import/parser, teste completo, auditoria de referências e áudio; compilação e FPS em aparelho real não foram realizados. **Proibido gerar APK sem pedido do usuário.** O workflow Android continua em `workflow_dispatch`, sem disparos pela branch. Próximo marco: v0.9 barco progressivo, madeira reforçada, cenas de embarque e QA visual.

# Checkpoint — 13/10/2026 — v0.8 cavernas exploráveis

Branch `feat/explorable-caves-v08`, derivada de `feat/wildlife-food-v072`. Adicionados interiores 3D originais para Caverna do Leste e Gruta das Raízes, portais de entrada e saída, colisão das salas, 4 caches únicos com materiais, planta contextual no minimapa e persistência da posição no interior usando save v3. Preservadas caça, construção modular, pesca, ferramentas, clima, fauna e barco de fuga legado. Próximos passos: QA Godot remoto/Android, visual das salas, enigmas e barco por etapas.

**Regra fixa:** não gerar, assinar, nem disparar workflow de APK até pedido explícito. Pipeline Android permanece manual e não foi alterado.

# Checkpoint — 13/10/2026 — v0.7.2 caça e alimentação

Branch `feat/wildlife-food-v072` parte de `feat/modular-shelter-v071`. Nova mecânica: fauna coletável (`crab`) e caça de javalis (`boar`) somente com lança de pedra equipada no slot utility; animação original da lança, coleta no contato, cozinhar caranguejo e carne na fogueira, inventário ampliado em cinco ícones/itens, armazenamento, fome/saúde e respawn determinístico de 900s registrado no mapa `harvested` do save v3. Fauna passiva (aves, tartarugas e peixes visuais), inventário/equipamento, clima, construção modular, pesca e barco originais foram mantidos. Testes automatizados ampliados.

**Preferência explícita:** usuário solicitou em 13/10/2026: "Avance e so faça apk quando eu pedir". Exportação Android AUTOMÁTICA DESLIGADA na branch, workflow `Build Android Beta APK` apenas manual. Não gerar APK, não oferecer exportação automática, não iniciar workflow manual a menos que o usuário peça. Continuar alterando, validando e publicando código-fonte no GitHub. Sem homologação visual/60 FPS em dispositivo.

# Checkpoint — 13/10/2026 — v0.7.1 abrigo modular

Branch `feat/modular-shelter-v071` parte de `feat/fauna-coast-v07`, que por sua vez preserva a base v0.6 de clima, corrida, ferramentas e pesca. Implementados módulos de porta e janela, geometria 3D procedural própria, dobradiça móvel, controle de passagem pela colisão, interação pelo botão Explorar, novos ícones, suporte modular compartilhado e prevenção de ocupação do mesmo soquete por painéis diferentes. O save mantém `SAVE_VERSION=3`, agora validando booleano `door_open` opcional para porta. Testes nativos expandidos verificam receitas, portas, passagem, save e duplicidade.

CI de importação, runtime e auditoria deve passar na branch final. O workflow Android exporta APK beta ARM64 com ID exclusivo `com.sergiomrge.gptsurvivor.beta.v071` e assinatura de teste; não atualizar a versão estável com esse pacote. Ainda pendentes: caça/drops, avaliação visual Android, cavernas interiores, construção destrutível/movível de módulos, barco por etapas e medições de FPS reais. Não afirmar que o beta é versão de produção.

# Checkpoint — 13/10/2026 — v0.7 fauna inicial

Branch `feat/fauna-coast-v07` criada a partir de `feat/visual-world-weather-v06`, mantendo a v0.6 intacta. Foi implementado `scripts/fauna.gd`: cinco espécies visuais modeladas no próprio Godot (caranguejo, tartaruga, javali, ave e peixe), povoamento determinístico, habitats por elevação e costa, movimento em ciclos de 0,12 s com descanso/vaguear/fugir, ocultação por distância e menor densidade no modo Leve. Vinculada ao ciclo de vida do mundo e do personagem em `world.gd` e `game.gd`. Há testes nativos adicionados ao `tests/test_survivor.gd`.

GitHub Actions `Validate Godot prototype` do commit `b80a8a2`: **success** (confirmado via API). Este sucesso não equivale à inspeção visual em celular, medição de FPS ou APK compilado. Fauna ainda não tem caça, drops, colisão com o jogador nem persistência por instância. Prioridades seguintes: investigar visualização no dispositivo, construir portas/janelas e suporte ao telhado; sistemas de caça/drops e fauna sonora; exploração de cavernas e barco visual por etapas. Não mudar o formato de save nem publicar v0.7 como final antes dos gates.

# Checkpoint — 13/10/2026 — v0.6.0

Branch `feat/visual-world-weather-v06` iniciada do commit `f047a2b2` da v0.5, preservando save, equipamentos e gameplay. Implementados: clima determinístico `SurvivorClimate`, partículas de chuva com modo leve, atmosfera noite/amanhecer/tempestade, solo molhado/ondas/vento nos shaders, coleta real de água sincronizada com chuva, botão correr e nova cinemática de caminhada/corrida, três estruturas modulares repetíveis (piso/parede/telhado) com modelo 3D, snap 3,2m, suporte, colisão e save. Testes de regressão ampliados a 182 e aprovados. Chaves privadas permanecem fora do repo. Android físico ainda pendente.

Autorização de publicar branches/commits já concedida, sem necessidade de novas perguntas. **Próximos marcos:** fauna e IA; cavernas e exploração com objetivos; construção modular avançada (portas/janelas/encaixes múltiplos); barco por etapas e sequência final. Sem prometer 60 FPS sem medição real. Ver `docs/ROADMAP_v06.md`.

# Checkpoint — 13/10/2026 — v0.5.0

Branch `feat/survival-camp-exploration-v05`, originada de `prototype-v0.4.2-equipment`. Requisitos escolhidos: (3) cordas/tábuas e manufatura por etapas; (4) rotação, indicador de área, mover acampamento sem custo; (5) baú, cama e coletor com chuva periódica; (6) pistas nos destroços/caverna e esquema de vela necessário ao barco. A lista recuperada terminava em 6: o item 7 não foi definido e não deve ser inventado.

Inventário e save v3 aceitam saves v1 e v2, com dados de equipamento persistidos, baú, água armazenada e rotação. Vida/fome/sede/recursos antigos permanecem. Build Android assinado v0.5 ainda precisa da mesma chave privada; apenas Godot headless/CI foi validado. Manter prioridade mobile-first e não chamar arte de preview de captura real do jogo.

# Checkpoint — 13/10/2026 — v0.4.1

## Autorização de publicação

Em 13/10/2026, Sergio autorizou permanentemente a publicação das atualizações deste projeto no GitHub: “Sempre pode publicar”. Prosseguir com commits e publicação das branches de desenvolvimento no repositório `sergiomrge-tech/Gpt-suvivor` sem repetir pedidos de confirmação. Manter chaves de assinatura, senhas e credenciais fora do repositório.

Base remota `22e5805aa08c50cbc139b36761075ed99aa58c25` em `prototype-v0.4-integrated`. Revisão em `prototype-v0.4.1-crafting`; main preservada.

Pedido do Sergio implementado: grade de inventário inspirada na organização da referência enviada (ícones originais e modelo real do jogo), aba Construções com faca/machado/picareta feitos à mão; árvore/coqueiro exigem machado e rocha exige picareta; troncos e pedras soltas coletáveis à mão na praia e pela ilha. Faca aumenta rendimento da fibra. Novas ferramentas são pagas/concedidas no contato, cancelamento anterior não cobra. Ferramentas não usam slots de estruturas.

Save v2 aceita v1 e mantém campos antigos/IDs de recursos; a geração das novas coletas usa seed separado e IDs próprios. Ferramentas não são concedidas gratuitamente na migração. Saves existentes continuam a partida; não desinstalar para atualizar. Zoom 12–48 com botões +/− e persistência; joystick raio 88 e área 220×220, afastado da borda.

Validação: 141 testes nativos, 13 auditorias de áudio e sete capturas reais em Godot Linux. APK ARM64 versão 401/0.4.1 com mesma chave privada da v0.4.0. Chave/senha ficam fora do repositório e dos entregáveis. Android físico permanece pendente para esta revisão.

## Histórico anterior

# Checkpoint — 13/10/2026 — v0.4.0

Projeto: GPT Survivor / Ilha: Último Voo. Repositório: https://github.com/sergiomrge-tech/Gpt-suvivor. Branch desta entrega: `prototype-v0.4-integrated`.

Base inicial `3df1ed7`; v0.2 validada localmente `4e4c658`; materiais v0.3 `5d7344a`. A branch remota main recebeu outro protótipo (`09fc7cf`) durante a v0.2. Esta entrega continua a base dos ZIPs validados e permanece isolada de main. Não substituir o trabalho paralelo sem reconciliar as implementações.

v0.4 implementa todas as seis frentes do documento de sugestões: personagem/articulações/ferramentas/poses; 13 sons originais, roteamento e mute; árvores coletáveis em sete grupos, samambaias/raízes e três trilhas; casa/bancada detalhadas e cais transitável; três descobertas originais persistentes; HUD compacto com mochila, diário, progresso e cancelamento. Foram preservados custos, itens e objetivo de escapar de barco.

Save continua versão 1, com campo opcional `discoveries` para manter compatibilidade com a v0.3. Coleta concede loot no contato; cancelar antes dele não concede. Construção/fabricação registra a transação no confirmar e anima depois, sem desfazer a transação ao cancelar a pose. Aproximação é local com deslizamento por eixos; não há navegação complexa do personagem. Capturas de QA impedem gravação de saves.

Validação: Godot 4.6.1 Linux, 101 testes nativos, 13 auditorias de WAV, capturas reais e teste do ZIP extraído. Android físico, reprodução auditiva, desempenho no aparelho e APK/AAB permanecem pendentes. Não alegar 60 FPS nem teste no celular. Próximo passo concreto: avaliar a versão jogável no Godot Android do Sergio e ajustar legibilidade, áudio e carga visual a partir do aparelho.

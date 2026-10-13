# QA — GPT Survivor v1.7.0 — 13/10/2026

- **Fonte original:** Godot 4.6.1, projeto GL Compatibility, saves v3 preservados; nenhuma alteração à ilha, loot, interfaces, navio ou lógica de interação.
- **Regressão focada:** torso e cabeça mantêm malhas unidas; novas botas de ponta arredondada têm um único mesh por pé e compartilham cache; superfície distingue pele/tecido/couro; tornozelos herdam a hierarquia dos joelhos e giram independentemente; todos os equipamentos continuam filhos de `right_hand`.
- **Visual:** `visual_hero_v17.yml` testa screenshots reais do jogo nos ângulos frontal/lateral/posterior, ciclo de passo, corte com machado, pesca e zoom mobile. Fixture do código real, não resultado de uma partida humana e não arte conceitual.
- **Plataforma:** render Linux/Xvfb não é Android e não valida FPS, memória ou usabilidade touch. Sem APK, por instrução do usuário.
- **Próximo gargalo:** retopologia de corpo/roupa profissional, textura original PBR em múltiplos canais e esqueleto/skinning com animação de produção, sem perder compatibilidade com equipamentos.

# QA — GPT Survivor v1.6.0 — 13/10/2026

- **Compatibilidade:** mantidos `SurvivorTerrain.height_at`, número e coordenadas de recursos, caminhos da ilha, save v3 e esquema de progressão. As novas famílias são exclusivamente decorativas e descartáveis ao construir.
- **Geometria:** troncos de praia/raízes musgosas originais em `scripts/biome_props.gd`, frondes arqueadas e folíolos separados em `SurvivorModels.palm`. A distribuição usa uma segunda semente estável e não altera as amostras anteriores.
- **Auditoria visual:** capturas preliminares mostraram frondes ocupando demais o campo de visão junto a coqueiros. Corrigido com desvanecimento seletivo da vegetação no corredor câmera→sobrevivente, com novo teste da posição da câmera no shader. Nova captura da revisão final ainda precisa passar no CI.
- **Desempenho:** malhas com `MultiMesh`, distâncias limitadas para os novos detalhes, sem sombras individuais e com densidade reduzida em Leve. Exige medição de FPS e memória em aparelho real antes de afirmar 60 FPS.
- **Testes:** importar no Godot 4.6.1, validar gameplay nativo e auditorias de projeto/áudio, gerar ZIP de fonte; `visual_biomes_v16.yml` captura 8 imagens reais, incluindo habitat 3 e 4, para revisão do visual. Somente declarar validação concluída quando os respectivos workflows do último commit aprovarem.
- **Limites honestos:** estética procedural mais rica, não é escultura AAA nem fotogrametria. Sem APK, sem teste físico Android e sem alegar inspeção visual manual dos PNGs, que ficam armazenados nos artefatos do workflow.

# QA — GPT Survivor v1.5.0 — 13/10/2026

- **Escopo:** melhorias geométricas e shader, sem mudanças nas posições salvas, estrutura da mochila, ferramentas, combate, cavernas ou fuga marítima.
- **Controles automatizados:** cobertura de juncos/samambaias/rochas com lotes multi-instanciados, terreno e saves v3 preservados, exclusão visual de trilhas/marcos/recursos, clima atingindo o shader, modo Leve reduzindo a densidade e árvore de madeira apresentando geometria foliar real.
- **CI:** `.github/workflows/validate.yml` é a barreira de parser Godot 4.6.1, gameplay, referências, áudio e ZIP de fonte. `.github/workflows/visual_biomes_v15.yml` produz 6 PNGs do framebuffer real em Linux/Xvfb sem imagens geradas artificialmente. Conferir resultado no GitHub Actions para o último commit.
- **Limitações conhecidas:** qualidade realista é incremental, não fotorrealismo; sem hardware Android, sem medição de FPS/memória/energia, e sem atestado auditivo. Estruturas decorativas não bloqueiam a circulação. Exportação Android só sob solicitação manual explícita.

# QA — GPT Survivor v1.4.0 — 13/10/2026

- Branch `feat/hero-anatomy-materials-v14` derivada da v1.3; fonte Godot 4.6.1, GL Compatibility e pipeline mobile existentes preservados.
- Verificações adicionadas: anatomia de perfis contínuos com normais, integração das malhas fundidas de cabeça/tronco, duas famílias de materiais de pele/cabelo, ativação exclusiva de microrelevo em qualidade Completo e desativação no modo Leve.
- Revisão visual automatizada: `.github/workflows/visual_hero_v14.yml` usa o Godot real em Xvfb para capturar 5 PNGs de personagem e praia; cenas de poses são fixtures do jogo e não prova de uma partida humana. O resultado precisa ser conferido no GitHub Actions e não é uma afirmação de igualdade a uma referência fotográfica.
- Limites: falta modelagem AAA/escultura, materiais PBR fotográficos licenciados, rig/skinning profissional, revisão artística humana, benchmarking em Android, medição FPS/temperatura e validação dos gestos no aparelho. Save v3 não foi alterado. NÃO gerar APK sem pedido explícito.

# QA — GPT Survivor v1.3.0 — 13/10/2026

- Branch `feat/cave-vents-voyage-hud-v13`, base v1.2 preservada. Testes de regressão nativos Godot 4.6.1: **445/445 aprovados** antes do último ajuste do workflow. Cobrem nova alternância de risco/silêncio do gás, luzes locais, distância de recife, HUD de integridade do casco e conservação de todos os fluxos anteriores.
- GitHub Actions `Native Godot screenshots - deep caves and sea voyage` aprovou quatro capturas reais do framebuffer: duas cavernas e duas cenas da embarcação. Isso comprova renderização da cena no Linux/Xvfb, não igualdade artística à referência nem taxa de quadros no celular.
- O workflow `Validate Godot prototype` estava aprovando testes mesmo com `rg` ausente na etapa de busca por erros de importação. Corrigido para usar `grep -E` disponível e interromper a importação quando ocorrer `SCRIPT ERROR` ou `ERROR:`. Revalidar no commit final antes de considerar a barreira de parser rigorosa.
- Ainda pendentes: testes físicos Android, gesto multitoque/rotação de tela, audição de loops ambientais e medição de FPS/energia. Nenhum APK solicitado ou gerado nesta revisão. Save v3 preservado e pipeline Android permanece estritamente manual.

# QA — GPT Survivor v0.6.0 — 13/10/2026

Validação nativa Godot 4.6.1 Linux: **182/182 testes de gameplay aprovados** no commit `b0abd7cb`, seguida de outras validações de integração. O workflow de cada commit também audita referências `res://` e 13 arquivos WAV mono PCM. Os testes desta versão acrescentam clima seco/chuva/temporal, vento, leve/completo, shader de umidade, botão sprint, postura de corrida, receitas repetíveis de piso/parede/telhado, encaixes de parede/telhado, colisão, save com módulos duplicados e regressões de pesca/acampamento/barco.

Limites: execução headless não comprova qualidade visual. **APK beta da v0.6:** gerar e conferir no workflow separado Build Android Beta APK; não declarar instalado ou testado em hardware Android sem evidência. Não houve captura real recente da v0.6, benchmarking 60 FPS, medição térmica nem QA de áudio por audição.

# QA — v0.5.0 — 13/10/2026

A suíte automatizada do Godot 4.6.1 na branch `feat/survival-camp-exploration-v05` cobre nova cadeia de corda/tábua/barco, pista da caverna, espaço de equipamentos, rotação de construção, cancelamento de relocação, baú com transferências sem duplicação, coletor de chuva e persistência do save v3. Foi executada no GitHub Actions, incluindo parser/importação, gameplay, referências e auditoria de WAV. O teste físico Android, desempenho/FPS, toque, qualidade dos modelos de acampamento e APK com assinatura preservada ainda não foram realizados nesta versão.

# QA atual — v0.4.1 — 13/10/2026

Godot 4.6.1 Linux: 141/141 verificações nativas aprovadas. Novas verificações cobrem recursos iniciais acessíveis, restrição de árvore/rocha sem ferramenta, fabricação com custos exatos, cancelamento anterior ao contato, rejeição de duplicatas, bônus da faca, persistência das ferramentas, migração v1→v2, zoom limitado, joystick reposicionado, grade do inventário, descrição de itens e painel limitado ao viewport.

Sete capturas reais em `tests/capture_inventory.gd` conferidas: praia/controles, mochila, ferramentas bloqueadas, receitas disponíveis, zoom próximo e duas telas em janela menor. Nenhum screenshot conceitual. × e abas permanecem fixos durante a rolagem.

APK release ARM64, package `com.sergiomrge.gptsurvivor`, versionCode 401/versionName 0.4.1. Chave de assinatura mantida da versão 0.4.0. Exportação, correção das authorities Startup/FileProvider, zipalign de 16 KiB, apksigner e CRC são exigidos pela rotina de build. A revisão atual ainda depende de teste físico no Android do usuário; verificação do arquivo não confirma instalação, toque nem FPS no aparelho.

## Histórico da v0.4.0

# QA — GPT Survivor v0.4.0

13/10/2026. Godot 4.6.1 stable Linux x86_64; renderização OpenGL Compatibility/Mesa llvmpipe. Não houve acesso ao celular.

## Verificações

- Importação/parsing e execução da cena sem erros de script.
- **101/101 verificações nativas**: ciclo até o barco; custos e restrições; orientação da malha; cozinha e sobrevivência; recuperação de cais/barco antigos; save/inventário/posição; descobertas e registro persistente sem duplicação; trilhas transitáveis após plantar árvores; ferramentas e poses; loot apenas no contato; cancelamento antes da coleta; cancelamento da pesca; piso do cais sobre o mar; mute/pausa e despacho de som; mochila/diário e multitoque.
- Auditoria dos **13/13 WAV**: mono PCM 16 bits/22050 Hz, arquivos não silenciosos, sem amostras clipadas e transições de loop dentro da faixa das transições do próprio sinal. Isso não substitui uma audição em hardware.
- Capturas reais da execução do menu, praia, construção, cavernas, nascente, acampamento, costa, mochila, diário, personagem, machadinha e pesca. As construções e poses de inspeção são fixtures montados pelo script; não representam uma partida humana completa.
- Auditoria de referências `res://`, completude e ausência de arquivos temporários; CRC do ZIP; importação e suíte repetidas após extração independente.

## Áudio e ambiente de teste

Como as sessões headless usadas aqui não oferecem saída auditiva para avaliação, nesse modo os arquivos e o roteamento são carregados/validados, mas não iniciamos playbacks em loop. Os loops ficam reservados à execução normal do jogo; nenhum teste de audição foi alegado. A pausa bloqueia o despacho de efeitos. Nas execuções gráficas, o ambiente utiliza driver Dummy; nenhuma audição real foi realizada. A saída Android usa o backend disponível no dispositivo e ainda precisa ser conferida.

## Capturas e persistência

`capture_runtime.gd` ativa um modo de captura que impede gravação de saves, inclusive no autosave ou ao fechar a janela. Os arquivos de testes de estado são removidos e saves anteriores restaurados. A malha das cavernas é nivelada localmente para manter o piso alinhado ao personagem. Os caminhos são calculados com AStarGrid2D e convertidos em uma máscara de chão, sem loops extensos no fragment shader.

## Reproduzir

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_survivor.gd
python3 tests/audit_project.py
python3 tests/audit_audio.py
```

Com display disponível:

```sh
godot --path . --rendering-method gl_compatibility --script res://tests/capture_runtime.gd -- --out=/caminho/para/capturas
```

`generate_noise.gd` reproduz o mapa de materiais; `generate_audio.py` reproduz os sons e requer NumPy apenas para a geração, não para jogar nem para auditar.

## Limites

Na v0.4.0, sem teste Android físico, APK/AAB, medição de FPS/temperatura/bateria no aparelho, teste de publicação ou avaliação auditiva em hardware. FPS em llvmpipe não é um benchmark Android. Warnings de V-Sync do display virtual são ambientais. Os modelos e animações são procedurais e ainda precisam de avaliação artística no aparelho. A coleta usa marcadores de animação, não física detalhada da ferramenta; caminhos de aproximação podem ser bloqueados, caso em que o jogador pode se aproximar por outro lado. Construção/fabricação registrada não é desfeita ao cancelar a resposta visual.

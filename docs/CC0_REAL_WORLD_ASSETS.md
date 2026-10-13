# GPT Survivor — Mundo realista: lote CC0 (13/10/2026)

## Direção aprovada
Priorizar **B — selva tropical densa**, com **A — praia tropical** no litoral e **C — costa rochosa** nas encostas. Preservar posicionamento do acidente (-8,164), recursos, passagens, cavernas, bancadas construídas e lógica de sobrevivência. Herói aprovado em branch separada: **MakeHuman B vestido, manter a roupa atual**. Não gerar APK sem solicitação.

## Modelos originais integrados na branch
- `assets/real_world/models/palm_detailed.glb` — palmeira realista próxima ao jogador, 16 frondes/960 folíolos, 8,25m visual. Licença CC0, [origem](https://www.innerscene.com/tools/library/3d-parts/palm-detailed-a8777b8c).
- `assets/real_world/models/palm_light.glb` — LOD leve para longe da praia inicial, 16 frondes/480 folíolos. CC0, [origem](https://www.innerscene.com/tools/library/3d-parts/palm-light-20c2a70c). Ambas representam palmeiras; **não contêm uma plantação botânica certificada de cocos**. Nossos cocos coletáveis continuam na lógica de recursos.
- `assets/real_world/models/airplane_propeller.glb` — monomotor civil texturizado, CC0, [origem](https://www.innerscene.com/tools/library/3d-parts/single-engine-propeller-aircraft-d6091ef1). A fuselagem original é um avião intacto, não um modelo pré-acidentado. O acidente é **cenografia composta**: fuselagem inclinada/semi-enterrada, solo danificado e pedaços metálicos; ainda requer pintura de avarias e, idealmente, modelagem das asas partidas por subdivisão, para alcançar qualidade final. Sua posição e colisão originais ficam inalteradas.
- `assets/real_world/models/workbench_carpenter.glb` — bancada de carpintaria com madeira e grampos, CC0, [origem](https://www.innerscene.com/tools/library/3d-parts/carpenter-workbench-carpentry-workbench-9855fae6). Somente modelo visual; receitas e alcance da bancada anteriores preservados.
- `assets/real_world/models/garden_shed.glb` — pequeno abrigo, CC0, [origem](https://www.innerscene.com/tools/library/3d-parts/garden-shed-2-x-3-m-original-exterior-model-80b9ac4b). Usado como modelo de casa no estágio atual; colisão anterior preservada. Sua escala deve ser revisada visualmente, não confundir com casa final de grande porte.
- `models/polyhaven/fern_02`, `calathea_orbifolia_01`, `pachira_aquatica_01` — samambaias, folhagens e árvores de selva reais. Fonte Poly Haven CC0. Quantidade-alvo atual: 31 samambaias, 18 folhagens e 7 árvores grandes, evitando trilhas/recursos, com LOD/redução no modo Leve.

## Superfície geográfica
Os materiais `aerial_beach_01` (A), `coast_sand_05` (B, dominante) e `seaside_rock` (C) usam scans reais CC0 1K, albedo + normalGL + rugosidade. As texturas do conjunto `coast_sand_rocks_02` também estão arquivadas para futuras transições rochosas. `shaders/ground.gdshader` mistura os scans usando a altura, inclinação e máscara de trilha existentes. O modo Leve omite samples extras de normal/roughness.

## Procedência e armazenamento
- Cada arquivo baixado por `tests/world_assets/download_cc0.py` tem SHA256/tamanho registrado em `assets/real_world/CATALOG.json`.
- Os originais CC0 também estão em **Biblioteca → Sobrevivência ilha → Assets**, nas subpastas `Coqueiros_3D`, `Aviao_Destrocos`, `Construcoes_Bancadas` e `Vegetacao_e_Terreno`. Mantido ZIP consolidado verificável.
- A integração está isolada em `feat/cc0-aviation-palms-crafting-world`, enquanto não houver teste visual nativo e regressão completa. Não atualizar `main` se CI falhar.

## Qualidade exigida antes de produção
- Executar `tests/test_world_cc0.gd` e `tests/test_survivor.gd` no Godot 4.6.1; validar render real em `tests/capture_cc0_world.gd`. Capturas Linux/Xvfb não equivalem a teste físico em Android.
- Garantir mobile-first, performance, distribuição coerente de vegetação densa, sem alterar a geometria física ou save v3. Só publicar em `main` depois de aprovar as capturas e testes.
- Os modelos antigos usados nos objetos ainda não contemplados por essa etapa (ferramentas, telhados modulares, caixas, cama e barco) deverão ser substituídos **por assets equivalentes com mesma interação** em próximos lotes. O lote atual não promete substituir literalmente todos os assets do jogo em uma única versão.

# GPT Survivor — Avaliação de assets de ilha realista (13/10/2026)

**Objetivo**: substituir a arte procedural sem sacrificar controles, construções, área de recursos, trilhas, save v3 nem FPS do Android. Esta branch é de *pesquisa e download para escolha*: **nada foi aplicado ao mapa**.

Fonte das 11 amostras: [Poly Haven](https://polyhaven.com), [licença CC0](https://polyhaven.com/license). Arquivos reais descargados via `tests/island_assets/download_options.py` e `.github/workflows/island_asset_options.yml`, resolução 1k (preview mobile). O CI valida integridade MD5 de cada arquivo com hashes devolvidos pela API. O workflow guarda os resultados como artifact `GPT-Survivor-CC0-Realistic-Island-Asset-Options`. Previews são thumbnails **oficiais** do fornecedor e NÃO prints in-engine ou imagens geradas.

## Opção A — Praia tropical natural
- `aerial_beach_01` — areia costeira com ondulações, mapas diffuse/normalGL/roughness.
- `palm_tree_bark` — casca de coqueiro com mapas PBR, **não é um coqueiro 3D**.
- `fern_02` — 4 moitas, ~6.232 triângulos no glTF baixado.
- `anthurium_botany_01` — 6 malhas de planta tropical, ~67.152 triângulos totais; usar LOD/subdivisão e instanciamento moderado.

## Opção B — Selva tropical densa
- `coast_sand_05` — solo escuro, cascalho e matéria orgânica, PBR.
- `coast_sand_rocks_02` — solo com pedras musgosas, PBR.
- `calathea_orbifolia_01` — conjunto com ~16.688 triângulos.
- `pachira_aquatica_01` — árvores e arbustos tropicais, ~76.914 triângulos; LOD obrigatório para uso denso.

## Opção C — Costa selvagem e rochosa
- `aerial_beach_02` — areia plana/úmida, PBR.
- `seaside_rock` — rocha erodida da praia, PBR.
- `coast_rocks_05` — formação rochosa capturada, **~771.724 triângulos no glTF original**. Proibida inclusão direta em cenário Android sem decimação/LOD/colisão simplificada.

## Direção recomendada
**Composição da ilha A + B + toques de C**: areia clara e coqueiros nas praias, vegetação forte nas encostas/interior, costas rochosas apenas em regiões específicas. Para resolução móvel: texturas 1k/2k, vertex budget conforme benchmark, LOD 2-3 etapas, MultiMesh para pequenos props, atlas e shaders simplificados, sem mascarar os requisitos de desempenho.

O coqueiro CC0 ainda precisa de um modelo arbóreo 3D de qualidade; a textura `palm_tree_bark` é apenas material de tronco. Candidatura externa para posterior aprovação: [Coconut Palm / evolveduk — Sketchfab](https://sketchfab.com/3d-models/coconut-palm-26e787f2ff2e4c0fb004c3b0210805a3) (~7,4k triângulos, **CC BY, crédito obrigatório**). Esse modelo externo NÃO está incluído nos pacotes CC0 baixados.

Assets baixados estão no artifact GitHub e nos arquivos ZIP separados entregues na conversa. Após escolha explícita, integrar à branch de desenvolvimento Godot e testar capturas reais, parser, saves, construção e FPS; **não produzir APK sem solicitação do usuário**.

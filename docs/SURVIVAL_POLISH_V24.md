# v2.4 — implementação das seis melhorias

Revisão sobre v2.3: 121 árvores antes decorativas agora são cortáveis; 14 ações usam animações reais dos 53 ossos; prévias e estruturas compartilham modelos; terreno e coqueiros receberam acabamento; coleta tem efeitos e troncos persistentes; APK foi otimizado e ganhou diagnóstico no aparelho.

## Comportamento

- Árvores instanciadas mantêm o desenho em lotes. Um proxy por tronco permite coleta, colisão e regeneração sem duplicar a malha. IDs determinísticos `canopy_tree_<candidato>` mantêm o estado entre sessões.
- Machado simples rende 8 madeiras: 5 imediatamente e 3 num tronco recolhível. Reforçado rende 12: 9 imediatamente e 3 no chão. O rendimento total anterior é preservado. Troncos persistem no save v4; saves v1, v2 e v3 migram. Recolher duas vezes não dá recompensa. Até 256 troncos pendentes; ao atingir esse limite, toda a madeira é entregue diretamente.
- Corte, mineração, faca, construção, fabricação, fabricação manual, coleta, busca, pesca, comida, bebida, cozimento, repouso e lança possuem clips específicos. Contato em 47% da ação continua sincronizado à recompensa. IK mantém apoio dos pés; ferramentas seguem a posição do osso da mão com dimensão em metros e orientação corrigida.
- Caminhada de 1,6 m/s e corrida de 2,88 m/s; a velocidade real de deslocamento governa a cadência e os sons de passos. O joystick analógico e colisões não aceleram uma marcha parada.
- `build_structure_visual` atende prévia e construção. Só o indicador de ocupação muda de cor; materiais reais permanecem visíveis. Limites medidos dos modelos orientam posicionamento e colisão. A casa tem colisão nas paredes com entrada transitável, excluindo telhado saliente e porta aberta do volume interno.
- Solo recebeu pequenas manchas orgânicas de húmus; folhas dos coqueiros têm verde menos luminoso e menor brilho. Modelos, UVs e texturas fotografadas permanecem.
- Árvores tombam e desaparecem; pedras se fragmentam. Efeitos temporários limitados a oito simultâneos, sem corpos físicos adicionais. Troncos coletáveis são recursos salvos independentes desses efeitos.
- Menu **Desempenho do aparelho** mostra FPS médio, tempo P95 dos quadros, chamadas de desenho e memória. Salva `user://performance_last.json`. Até 600 amostras móveis, coletadas durante jogo ativo. Nenhum FPS é inventado antes das amostras. Memória de renderização depende do driver; temperatura e bateria não são medidas.

## APK

`GPT_Survivor_v2_4_0_Melhorias_Completas.apk`: 151135492 bytes / 144,13 MiB, contra 179,17 MiB na v2.3 (redução de 19,55%). Modelos originais duplicados saem do pacote; 21 cenas nativas já normalizadas permanecem. Texturas 3D usam compressão VRAM e mipmaps; elementos do mundo têm limite de 1024 px. Texturas do herói mantêm resolução original; interface permanece inalterada. Fontes dos assets não são alteradas.

- Godot 4.6.1, ARM64, Android mínimo 24 e alvo 35.
- Pacote `com.sergiomrge.gptsurvivor.worldbeta`, versão `2400` / `2.4.0-world-beta`.
- Mesma chave privada de teste da v2.3; chave não está no repositório.
- SHA-256 `8e3ea8f82a7fce5d97ca930aa8460546015a10e72ca4eb10c6083e17f14e5e15`.
- `apksigner verify --verbose`: v2/v3 aprovadas; `zipalign -c -P 16 4`: aprovado; CRC de todas as entradas: aprovado.
- Correção reproduzível do manifesto altera exclusivamente a authority de AndroidX Startup, preservando FileProvider.

## Validação

Godot nativo: progressão **669/669**, mapa **1193/1193**, mundo CC0 **44/44**, locomoção **2164 sem falhas**, novas melhorias **437/437**. Auditoria de referências e 13 arquivos PCM aprovada. Captura do framebuffer real verificou ações, modelos iguais, fragmentos e ocultação das árvores MultiMesh. Renderizador utilizado na inspeção: Mesa llvmpipe, não GPU Android.

Pack exportado inicia com template Linux sem arquivos-fonte, demonstrando que os assets removidos têm substitutos no runtime. Esse teste não comprova instalação Android, toque real, temperatura ou FPS em celular físico. Essas medições continuam pendentes no aparelho; o painel permite registrar FPS e memória durante a sessão.

## Reprodução

```sh
Godot_v4.6.1-stable_linux.x86_64 --headless --path . --editor --import --quit
python3 tools/optimize_mobile_textures.py
Godot_v4.6.1-stable_linux.x86_64 --headless --path . --editor --import --quit
Godot_v4.6.1-stable_linux.x86_64 --headless --path . --script res://tools/bake_world_assets.gd
Godot_v4.6.1-stable_linux.x86_64 --headless --path . --script res://tests/test_survival_polish_v24.gd
Godot_v4.6.1-stable_linux.x86_64 --headless --path . --export-debug Android /tmp/survivor-unsigned.apk
```

Depois: corrigir manifesto com `tools/android/fix_android_manifest.py`, alinhar com Build Tools 35.0.1, assinar com chave persistente e executar os três gates acima. Não executar outro export sobre o APK final assinado. Workflows configuram a mesma preparação e validação; chaves temporárias do CI não substituem a chave persistente para atualizar uma instalação existente.

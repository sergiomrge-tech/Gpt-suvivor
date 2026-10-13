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

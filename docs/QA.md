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

Sem teste Android físico, APK/AAB, medição de FPS/temperatura/bateria no aparelho, teste de publicação ou avaliação auditiva em hardware. FPS em llvmpipe não é um benchmark Android. Warnings de V-Sync do display virtual são ambientais. Os modelos e animações são procedurais e ainda precisam de avaliação artística no aparelho. A coleta usa marcadores de animação, não física detalhada da ferramenta; caminhos de aproximação podem ser bloqueados, caso em que o jogador pode se aproximar por outro lado. Construção/fabricação registrada não é desfeita ao cancelar a resposta visual.

# Correção da caminhada — 14/10/2026

Base: `a33c4c4`, branch com a vegetação realista e MakeHuman vestido.

## Causa confirmada no Godot 4.6.1

O clip `walk` do GLB troca os lados dos membros: em amostra de início,
`foot_l.x=-0.161` e `foot_r.x=+0.215`, embora o bind pose use os lados
opostos. Os braços também atravessam o tronco. Idle/walk/run importados
estavam com `loop_mode=0`. O controlador ainda aplicava a inclinação e
o balanço do personagem procedural ao pai do esqueleto real.

## Correção

- Clipes locais idle/walk/run construídos sobre o bind pose real, com IK
  de duas juntas para as pernas, joelhos para a frente e solas alinhadas.
- Ciclos contínuos com costura início/fim e transição de 0,18 s.
- Braços ao lado do corpo e movimento alternado em relação às pernas.
- Removida a inclinação/balanço duplicado do pai do modelo importado.
- Direção do corpo baseada no deslocamento efetivo após colisão.
- GLB original, roupa, materiais, ossos, ferramentas e mapa preservados.

## Validação

- Godot 4.6.1: importação/parsing sem erros.
- `test_hero_locomotion.gd`: 2164 verificações, zero falhas; cobre ambos
  os lados, apoio dos pés, tronco, loop, transições e vínculo da ferramenta.
- Capturas reais locais da pose parada, caminhada e corrida inspecionadas.
- `test_world_cc0.gd`: 44/44 verificações de integração do mundo aprovadas.
- Auditoria de referências e estrutura do GLB aprovadas.
- A suíte antiga `test_survivor.gd` possui incompatibilidades anteriores
  à correção com os novos assets: espera uma palmeira procedural fundida e
  tenta ler `camera_world_position` ausente no material atual (linha 305).
  Essa execução não constitui aprovação da suíte completa.
- Sem teste físico Android ou medição de FPS no aparelho nesta correção.

Não altera velocidade de deslocamento, salvamento, colisões ou recursos.

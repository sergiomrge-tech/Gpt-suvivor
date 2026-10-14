# Dungeons Fires: As Cinco Brasas - v0.1.0

Projeto Godot independente em `projects/dungeons-fires`. O jogo Survivor original, na raiz do repositório, permanece preservado.

## O que esta versão permite jogar

- Hub com forja, fabricação, equipamentos, talentos iniciais e cinco estruturas aprimoráveis.
- Mapa com quinze expedições desbloqueadas em sequência, cinco temas e cinco salas por expedição.
- Varek inicialmente; Maela após três masmorras; Neris após seis. Seis famílias de arma com aparência correspondente.
- Combo, esquiva, duas técnicas por herói, suprema, poções e inimigos com aviso antes do golpe.
- Loot de recursos/equipamentos, 120 definições de itens, melhorias até +10 e relíquias de chefes.
- Save local com gravação temporária/backup e retomada preservando vida, poções, inimigos e saque.
- Controles por toque; opções de áudio, tremor, zoom e dificuldade História/Aventura.

## Escopo real e limites

Esta é a primeira versão jogável do projeto, não o lançamento final descrito no GDD. O desenho pixel art é original e inicial, com poses animadas construídas por código. A fidelidade artística à direção solicitada ainda requer avaliação e refinamento.

As quinze expedições usam encontros e arenas derivados de templates; não são quinze masmorras finais com level design exclusivo. Há três arquétipos comuns e variações de chefes. Cada classe tem duas técnicas fixas nesta versão; as 18 skills planejadas e as árvores completas ainda não estão implementadas. Talentos atuais aumentam vida/ataque. Estruturas Arquivo/Quartel têm aprimoramento persistente e leitura narrativa, mas missões pessoais/arena/contratos ainda são futuros. Não há afixos aleatórios, desmontagem, loadouts, Veterano ou quatro sets visuais de armadura por herói.

Equipamentos repetidos ou recebidos com mochila cheia convertem em três minérios, regra temporária mostrada no inventário. Primeiras conclusões também garantem uma arma compatível. A duração de 8-15 minutos do GDD é uma meta futura; as arenas de v0.1 são mais curtas.

## Abrir e jogar

Abra o `project.godot` desta pasta com Godot 4.6.1 ou versão compatível. O projeto precisa ser aberto separadamente do Survivor da raiz. O import de assets é feito pelo editor. Android: APK para arm64, Android 7.0/API 24 ou superior, tela horizontal, sem acesso à internet obrigatório.

Teclado de teste: WASD/setas para andar; J/espaço golpe; K esquiva; Q/E técnicas; R suprema; H cura; Esc pausa/voltar. No celular, use o analógico e os botões desenhados na base da tela. Comece pela Mina dos Sinos no mapa.

## Validação

Execute no diretório do projeto:

```bash
godot --headless --editor --import --quit
godot --headless --script tests/test_game.gd -- --qa
godot --headless --script tests/test_combat_bot.gd -- --qa
```

O argumento QA usa saves separados e suprime áudio nos testes. Não distribua scripts internos de teste dentro do APK final.

Use o preset Android para exportação. `tools/package_android.py` remove apenas testes e assinaturas antigas, preserva metadados restantes, adiciona licenças, alinha a 16 KB, assina com chave privada externa e verifica o resultado com Android SDK Build Tools. Nunca inclua keystore ou senha no repositório. A chave deve ser preservada para permitir atualizações sobre o APK instalado.

Os generators `tools/create_art.py` e `tools/create_content.py` permitem reproduzir os assets e o catálogo; não substituem revisão artística. A fonte DejaVu tem licença anexada. Não foram usados sprites ou músicas de Golden Axe.

Leia `docs/GDD_v1.md` para o projeto completo e `docs/QA_v0_1.md` para evidências e limitações desta build.

# Dungeons Fires: As Cinco Brasas - v0.2.0

Projeto Godot independente em `projects/dungeons-fires`. O jogo Survivor original, na raiz do repositório, permanece preservado.

## O que esta versão permite jogar

- Hub com forja, fabricação, equipamentos, talentos iniciais e cinco estruturas aprimoráveis.
- Mapa com quinze expedições desbloqueadas em sequência, cinco temas e cinco salas por expedição.
- Varek inicialmente; Maela após três masmorras; Neris após seis. Seis famílias de arma com aparência correspondente.
- Combo, esquiva, 18 habilidades com escolha de duas por herói, supremas distintas, barreiras, marcas, armadilhas e zonas persistentes.
- Nove ramos de talentos, 54 nós, ranks, pré-requisitos, gates do santuário e redistribuição gratuita.
- Encontros em formações diferentes, perigos avisados, baú por expedição e padrões de chefes.
- Quartel com sete marcos narrativos de recompensa única e treino sem saque/XP.
- Loot de recursos/equipamentos, 120 definições de itens, melhorias até +10 e relíquias de chefes.
- Save versão 2, migração da v1 e retomada preservando vida, poções, cooldowns, barreiras, marcas, zonas, projéteis, avisos de perigo e saque. Pontos do talento provisório v1 são devolvidos.
- Controles por toque; opções de áudio, tremor, zoom e dificuldade História/Aventura.

## Escopo real e limites

Esta é a primeira versão jogável do projeto, não o lançamento final descrito no GDD. O desenho pixel art é original e inicial, com poses animadas construídas por código. A fidelidade artística à direção solicitada ainda requer avaliação e refinamento.

As quinze expedições usam arenas e kits compartilhados com formações/ameaças diferenciadas; não são quinze masmorras finais com level design exclusivo. Há três arquétipos comuns e variações de chefes. As 18 habilidades e 54 nós estão funcionais, mas a animação específica de cada técnica e o acabamento artístico ainda precisam evoluir. O quartel tem treino e sete contratos de marcos, sem arena de desafios ou contratos repetíveis. Não há afixos aleatórios, desmontagem, loadouts, Veterano ou quatro sets visuais de armadura por herói.

Equipamentos repetidos ou recebidos com mochila cheia convertem em três minérios, regra temporária mostrada no inventário. Primeiras conclusões também garantem uma arma compatível. A duração de 8-15 minutos do GDD é uma meta futura; as arenas de v0.1 são mais curtas.

## Abrir e jogar

Abra o `project.godot` desta pasta com Godot 4.6.1 ou versão compatível. O projeto precisa ser aberto separadamente do Survivor da raiz. O import de assets é feito pelo editor. O APK disponível continua sendo v0.1.0 para arm64/Android API 24+. A fonte v0.2.0 usa o mesmo package e preset versionCode 200, mas não foi exportada ou testada no Android. A chave original e o SDK/templates não estavam acessíveis nesta retomada; a atualização instalável está pendente.

Teclado de teste: WASD/setas para andar; J/espaço golpe; K esquiva; Q/E técnicas; R suprema; H cura; Esc pausa/voltar. No celular, use o analógico e os botões desenhados na base da tela. Comece pela Mina dos Sinos no mapa.

## Validação

Execute no diretório do projeto:

```bash
godot --headless --editor --import --quit
godot --headless --script tests/test_game.gd -- --qa
godot --headless --script tests/test_v02.gd -- --qa
godot --headless --script tests/test_combat_bot.gd -- --qa
```

O argumento QA usa saves separados e suprime áudio nos testes. Não distribua scripts internos de teste dentro do APK final.

Use o preset Android para exportação. `tools/package_android.py` remove apenas testes e assinaturas antigas, preserva metadados restantes, adiciona licenças, alinha a 16 KB, assina com chave privada externa e verifica o resultado com Android SDK Build Tools. Nunca inclua keystore ou senha no repositório. A chave deve ser preservada para permitir atualizações sobre o APK instalado.

Os generators `tools/create_art.py` e `tools/create_content.py` permitem reproduzir os assets e o catálogo; não substituem revisão artística. A fonte DejaVu tem licença anexada. Não foram usados sprites ou músicas de Golden Axe.

Leia `docs/GDD_v1.md` para o projeto completo e `docs/QA_v0_2.md` para evidências e limites desta versão de fonte. O APK anterior está documentado em `docs/QA_v0_1.md`.

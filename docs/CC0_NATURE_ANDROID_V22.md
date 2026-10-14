# GPT Survivor — Integração mobile realista de sete assets Poly Haven CC0

Branch de implementação: `feat/survivor-nature-realistic-apk`.

Assets comprados: **nenhum**; sete originais licenciados CC0 previamente baixados,
verificados com hashes e preservados na Biblioteca, no GitHub (`assets/cc0-trees-rocks-structures-oct2026`)
e nos ZIPs por categoria. O script revalida os ZIPs e entradas antes da importação.

**No mundo:**
- `island_tree_01` aparece entre as árvores coletáveis na floresta, com escala realista e controle de alcance.
- `pachira`, já presente, preenche as demais copas no lugar dos modelos geométricos.
- `boulder_01` e `rock_07` passam a representar depósitos de pedra coletáveis.
- `dead_tree_trunk_02` substitui troncos soltos, preservando a coleta manual.
- `tree_stump_01` pontua as clareiras da floresta.
- `rock_face_01` forma paredes de rocha próximas às duas cavernas.
- `wooden_ladder_02` aparece no entorno da gruta e de casas construídas.

Não alterados: IDs de recursos, regras de equipamento obrigatório para árvores/pedras,
salvamentos, receita do barco e progressão. Modelos de rocha/caverna e escadas não
têm colisão nem interação nova; são visuais até a mecânica correspondente existir.

A conversão usa `@gltf-transform/cli@4.2.1 simplify` com meshoptimizer para reduzir
polígonos mantendo UVs/materiais/texturas. O processo exige aprovação em CI Godot 4.6.1
e capturas reais do jogo antes de publicar APK Android arm64 de teste.
O pacote de teste usa identidade Android separada (`com.sergiomrge.gptsurvivor.naturebeta`)
e assinatura de testes gerada na compilação; não é um release Play Store.
Fonte/licença: https://polyhaven.com/license.

**Importante:** desempenho FPS real em celular só pode ser confirmado no aparelho.

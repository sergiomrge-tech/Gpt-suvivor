# QA - Dungeons Fires v0.1.0

## Build entregue

Godot 4.6.1 stable oficial. Package `com.sergiomrge.dungeonsfires`; versionCode 100; versionName 0.1.0. Android mínimo API 24, alvo API 35, somente arm64-v8a. APK horizontal, independente do Survivor.

APK: 28,415,938 bytes. SHA-256:

`49d943588a4d2d7ded4ed91c976d753d82ed59bb5e0d58009b5908dd0122446b`

## Evidências concluídas

- Import/parser do projeto final aprovados, sem erro de GDScript no log final.
- Suíte nativa: 139 verificações, zero falhas e sem erro de runtime ou aviso de recursos pendentes ao encerrar.
- A mesma suíte executou novamente sobre os assets e scripts compilados extraídos do APK final: 139 verificações, zero falhas.
- Grafo de campanha e transações verificados nas quinze masmorras / 75 salas. A suíte força a conclusão de inimigos para testar transições e recompensas; isso não mede dificuldade ou qualidade visual de toda a campanha.
- Teste de combate adicional: bot usa movimento, ataque, esquiva, técnicas e cura para vencer a Mina dos Sinos sem forçar morte de inimigos. Vitória em aproximadamente 24 segundos de simulação; esse valor não é medição de FPS nem duração de uma sessão humana.
- Equipar respeita classe; upgrades cobram valores exatos; crafting duplicado é recusado; desbloqueios de oficina e herói são verificados; recompensa inicial não se repete; backup recupera save inválido.
- Multitouch com identificadores separados, liberação de ataque e reset de controles testados por eventos nativos. Não substitui teste com dedos em aparelho.
- Apksigner oficial: assinatura válida v2/v3, sem forçar mínimo SDK diferente do manifesto.
- Zipalign oficial: alinhamento 16 KB aprovado. CRC de todas as entradas aprovado.
- Catálogo presente no APK, com 120 definições; cenas e scripts remapeados carregam a partir do payload exportado.
- Testes internos removidos do pacote; licenças adicionadas. Nenhuma chave, senha ou fonte de projeto estranho incluída.

## Limitações de validação

Não havia aparelho Android/emulador conectado. Instalação, primeira abertura no Android, toque físico, aquecimento e FPS GPU ainda não foram confirmados. O ambiente também não permitiu criar o servidor de tela necessário para renderizar a revisão gráfica; os testes Godot foram headless. Não há screenshot real desta entrega, nem aprovação de fidelidade visual a Golden Axe.

Arte, composição das arenas, balanceamento e interface são iniciais. A campanha usa templates e três arquétipos comuns; o GDD descreve uma produção mais rica que ainda precisa ser desenvolvida. Árvore de talentos completa, 18 skills, afixos, contratos, arena e missões pessoais não estão prontos. Esta build deve ser tratada como primeiro protótipo jogável.

## Começar a avaliação

Abrir o app, entrar no refúgio, selecionar Mapa de Masmorras e Mina dos Sinos. Usar analógico, Golpe, Esquiva e Técnicas; Curar possui cargas limitadas. Ao vencer, retornar e conferir saque na mochila/forja. Fechar e retomar uma expedição deve preservar vida, poções e progresso de sala. Opção História reduz dano recebido.

Não desinstalar automaticamente builds futuras para resolver conflitos; preservar a assinatura e incrementar versionCode para manter os saves.

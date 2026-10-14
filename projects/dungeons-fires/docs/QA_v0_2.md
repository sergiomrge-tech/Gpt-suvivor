# Dungeons Fires v0.2.0 - fonte validada

## Alterações verificadas

- 18 habilidades funcionais e configuráveis em dois slots por herói. Liberação por nível, recarga, mana, troca de slots sem duplicação e bloqueio de edição durante expedição pendente.
- Nove ramos e 54 nós de talentos. Ranks, pontos, requisitos por ramo e nível do santuário; bônus distintos de vida, defesa, ataque, crítica, cura, recargas, ruptura, barreira, mana, movimento e suprema. Redistribuição gratuita no refúgio.
- Campos persistentes, marcas detonáveis, escudos absorventes, enfraquecimento, armadilhas e distração. Supremas diferenciadas entre os três heróis.
- Formações e ameaças por masmorra/sala; perigos regionais com preparação visível; baú na terceira sala; comportamentos de chefe por perfil.
- Quartel com treino sem XP/loot e sete contratos narrativos de marco com recompensa única.
- Save schema 2. Migração do schema 1 preserva itens, moedas, equipamentos e fases; pontos do talento provisório são devolvidos. A vida de expedição é limitada ao novo máximo de vida após a migração.
- Retomada de expedição guarda estados, recargas, marcas, escudos, zonas, projéteis, hazards, loot e estado do RNG. Backup atualizado após transação bem-sucedida.
- Cadência de corrida vinculada ao deslocamento; HUD atualizado a 10 Hz para evitar recalcular toda a interface a cada frame.

## Resultados locais

Godot 4.6.1 stable oficial: import e parser sem erros. Suíte de regressão: 139/139. Suíte nova: 82/82. Total: 221 verificações, zero falhas, sem erro de runtime nos logs finais. Bot adicional venceu a Mina dos Sinos usando combate normal, sem morte forçada de inimigos.

Os testes verificam as dezoito habilidades individualmente, pontos/pré-requisitos, caps, redistribuição, bloqueio de build, migração, recompensa única, persistência de efeitos, baú único e treino sem ganho econômico. Auditoria independente: nenhuma referência quebrada e nenhum arquivo temporário/segredo na fonte.

Os testes foram headless. Esses resultados não comprovam renderização, conforto de toque físico, FPS GPU ou equilíbrio integral de todas as builds. As arenas e artes continuam sendo uma base inicial; assets finais, animações exclusivas por skill e level design autoral de cada masmorra permanecem no planejamento.

## Android pendente

Não foi gerado APK v0.2.0. Nesta retomada, o SDK/templates Android e a chave privada usada no APK v0.1.0 não estavam disponíveis. A chave anterior foi criada fora dos arquivos persistidos e não foi preservada corretamente. Não é possível comprovar atualização sobre a instalação v0.1 sem essa chave; não substituir a assinatura silenciosamente nem orientar desinstalação com perda de save.

O APK v0.1 continua válido e inalterado. O preset da fonte passa a versionCode 200/versionName 0.2.0, mantendo o package original. SDK/templates, identidade de assinatura e teste Android precisam ser resolvidos antes de exportar a próxima atualização instalável.

O workflow independente agora executa também a suíte v0.2 e verifica o CRC do arquivo de fontes. Sua execução remota deve ser consultada separadamente; o sucesso local não é apresentado como CI já aprovado.

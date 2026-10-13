# Checkpoint — 13/10/2026 — v0.4.2

Base correta: `prototype-v0.4.1-crafting`; continuação preservada na branch `prototype-v0.4.2-equipment`. O `main` permanece um protótipo v0.2 paralelo; nunca substituir seu histórico ou copiar arquivos dessa versão antiga por cima da base 0.4.x. Um PR antigo do ramo v0.2 foi fechado sem merge por esta razão.

Pedido do usuário: área separada **Equipar** para mão principal (vara de pescar) e ferramenta (faca, machado e picareta), com ícones, identificação de equipado, ações de equipar/desequipar e persistência. A vara fabricada na bancada é equipada automaticamente; a ação PESCAR continua aparecendo para orientar como utilizá-la. Colheita de árvores/coqueiros exige machado equipado; pedra exige picareta equipada; faca só dá bônus às fibras quando equipada. Troncos, pedras soltas e fibras iniciais permanecem coletáveis sem ferramentas.

Save atual continua `SAVE_VERSION = 2`, com um campo novo e opcional `equipment`; saves antigos v1/v2 sem esse campo migram automaticamente sem recomeçar a campanha, equipando ferramentas já possuídas. Testes nativos foram ampliados para cobrir migração, troca de slot, pesca sem a vara equipada, equipar após a fabricação e o fluxo do HUD.

Metadados de lançamento: `config/version=0.4.2`, `version/code=402`, `version/name=0.4.2`. O código-fonte e testes são publicados no GitHub; **APK de v0.4.2 ainda não foi exportado nem assinado**. Para poder atualizar a instalação já existente preservando o save, é obrigatório utilizar a mesma chave privada da v0.4.0/0.4.1. Android físico, toque e FPS ainda precisam ser confirmados.

## Histórico anterior

# Checkpoint — 13/10/2026 — v0.4.1

## Autorização de publicação

Em 13/10/2026, Sergio autorizou permanentemente a publicação das atualizações deste projeto no GitHub: “Sempre pode publicar”. Prosseguir com commits e publicação das branches de desenvolvimento no repositório `sergiomrge-tech/Gpt-suvivor` sem repetir pedidos de confirmação. Manter chaves de assinatura, senhas e credenciais fora do repositório.

Base remota `22e5805aa08c50cbc139b36761075ed99aa58c25` em `prototype-v0.4-integrated`. Revisão em `prototype-v0.4.1-crafting`; main preservada.

Pedido do Sergio implementado: grade de inventário inspirada na organização da referência enviada (ícones originais e modelo real do jogo), aba Construções com faca/machado/picareta feitos à mão; árvore/coqueiro exigem machado e rocha exige picareta; troncos e pedras soltas coletáveis à mão na praia e pela ilha. Faca aumenta rendimento da fibra. Novas ferramentas são pagas/concedidas no contato, cancelamento anterior não cobra. Ferramentas não usam slots de estruturas.

Save v2 aceita v1 e mantém campos antigos/IDs de recursos; a geração das novas coletas usa seed separado e IDs próprios. Ferramentas não são concedidas gratuitamente na migração. Saves existentes continuam a partida; não desinstalar para atualizar. Zoom 12–48 com botões +/− e persistência; joystick raio 88 e área 220×220, afastado da borda.

Validação: 141 testes nativos, 13 auditorias de áudio e sete capturas reais em Godot Linux. APK ARM64 versão 401/0.4.1 com mesma chave privada da v0.4.0. Chave/senha ficam fora do repositório e dos entregáveis. Android físico permanece pendente para esta revisão.

## Histórico anterior

# Checkpoint — 13/10/2026 — v0.4.0

Projeto: GPT Survivor / Ilha: Último Voo. Repositório: https://github.com/sergiomrge-tech/Gpt-suvivor. Branch desta entrega: `prototype-v0.4-integrated`.

Base inicial `3df1ed7`; v0.2 validada localmente `4e4c658`; materiais v0.3 `5d7344a`. A branch remota main recebeu outro protótipo (`09fc7cf`) durante a v0.2. Esta entrega continua a base dos ZIPs validados e permanece isolada de main. Não substituir o trabalho paralelo sem reconciliar as implementações.

v0.4 implementa todas as seis frentes do documento de sugestões: personagem/articulações/ferramentas/poses; 13 sons originais, roteamento e mute; árvores coletáveis em sete grupos, samambaias/raízes e três trilhas; casa/bancada detalhadas e cais transitável; três descobertas originais persistentes; HUD compacto com mochila, diário, progresso e cancelamento. Foram preservados custos, itens e objetivo de escapar de barco.

Save continua versão 1, com campo opcional `discoveries` para manter compatibilidade com a v0.3. Coleta concede loot no contato; cancelar antes dele não concede. Construção/fabricação registra a transação no confirmar e anima depois, sem desfazer a transação ao cancelar a pose. Aproximação é local com deslizamento por eixos; não há navegação complexa do personagem. Capturas de QA impedem gravação de saves.

Validação: Godot 4.6.1 Linux, 101 testes nativos, 13 auditorias de WAV, capturas reais e teste do ZIP extraído. Android físico, reprodução auditiva, desempenho no aparelho e APK/AAB permanecem pendentes. Não alegar 60 FPS nem teste no celular. Próximo passo concreto: avaliar a versão jogável no Godot Android do Sergio e ajustar legibilidade, áudio e carga visual a partir do aparelho.

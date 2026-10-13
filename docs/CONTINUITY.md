# Checkpoint — 13/10/2026 — v0.4.0

Projeto: GPT Survivor / Ilha: Último Voo. Repositório: https://github.com/sergiomrge-tech/Gpt-suvivor. Branch desta entrega: `prototype-v0.4-integrated`.

Base inicial `3df1ed7`; v0.2 validada localmente `4e4c658`; materiais v0.3 `5d7344a`. A branch remota main recebeu outro protótipo (`09fc7cf`) durante a v0.2. Esta entrega continua a base dos ZIPs validados e permanece isolada de main. Não substituir o trabalho paralelo sem reconciliar as implementações.

v0.4 implementa todas as seis frentes do documento de sugestões: personagem/articulações/ferramentas/poses; 13 sons originais, roteamento e mute; árvores coletáveis em sete grupos, samambaias/raízes e três trilhas; casa/bancada detalhadas e cais transitável; três descobertas originais persistentes; HUD compacto com mochila, diário, progresso e cancelamento. Foram preservados custos, itens e objetivo de escapar de barco.

Save continua versão 1, com campo opcional `discoveries` para manter compatibilidade com a v0.3. Coleta concede loot no contato; cancelar antes dele não concede. Construção/fabricação registra a transação no confirmar e anima depois, sem desfazer a transação ao cancelar a pose. Aproximação é local com deslizamento por eixos; não há navegação complexa do personagem. Capturas de QA impedem gravação de saves.

Validação: Godot 4.6.1 Linux, 101 testes nativos, 13 auditorias de WAV, capturas reais e teste do ZIP extraído. Android físico, reprodução auditiva, desempenho no aparelho e APK/AAB permanecem pendentes. Não alegar 60 FPS nem teste no celular. Próximo passo concreto: avaliar a versão jogável no Godot Android do Sergio e ajustar legibilidade, áudio e carga visual a partir do aparelho.

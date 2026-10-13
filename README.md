# GPT Survivor — Ilha: Último Voo

**Protótipo jogável v0.4.1 • Godot 4.x • 3D top-down • Android e PC**

Um sobrevivente de um acidente aéreo precisa explorar uma ilha tropical de aproximadamente 400 metros de diâmetro, montar seu acampamento e construir um barco para voltar para casa.

## Abrir no celular com Godot Android

1. Baixe e extraia `GPT_Survivor_Godot_v0_4_1.zip` em uma pasta acessível, por exemplo `Downloads/GPT_Survivor`.
2. Abra o Godot Android e escolha **Importar**. Selecione o arquivo `project.godot` da pasta extraída. Se a versão do editor permitir importar ZIP, também é possível selecionar o ZIP diretamente.
3. Abra o projeto. Use o celular na horizontal e toque em **▶ Executar projeto**.
4. No jogo, toque em **Nova sobrevivência** e depois **Acordar na praia**.

A primeira importação pode levar alguns segundos. O projeto gera as malhas localmente e não depende de downloads, APIs ou plugins. Recomenda-se Godot 4.4 ou superior; a validação desta entrega foi feita no Godot 4.6.1 Linux. O APK Android 64-bit v0.4.1 é entregue separadamente. O projeto pode ser aberto no editor Godot para desenvolvimento.

## Controles

- **Celular:** Mochila abre a grade de itens, o personagem, o diário e a aba Construções; joystick maior à esquerda, afastado da borda; +/− abaixo do minimapa ajusta o zoom; ação, pesca, construção e alimentação à direita. Use dois dedos para mover e interagir ao mesmo tempo. Arraste a lista de receitas para ver todos os itens; × fecha o painel.
- **PC:** WASD/setas para andar; E ação; B construção; F pesca/cancelar construção; H comer/beber; P salvar; Esc pausa/fechar; +/− aproximação da câmera.
- **Construções:** selecione uma receita, mova o personagem para posicionar a prévia verde, toque em Confirmar. A prévia vermelha informa o impedimento. Nenhum recurso é gasto até confirmar um local válido.

## Partida completa

1. Recolher troncos (3 madeiras cada), pedras soltas (2 pedras cada) e fibras à mão. Abra **Mochila → Construções**: machado de pedra = 3 madeiras + 2 pedras + 2 fibras; picareta = 3 madeiras + 3 pedras + 2 fibras; faca = 1 madeira + 2 pedras + 1 fibra. Sem bancada. Árvores/coqueiros exigem machado; rochas exigem picareta. Faca melhora a coleta de fibras de 5 para 8. Metal dos destroços é recuperado à mão.
2. Construir fogueira (10 madeiras, 6 pedras) e bancada (16 madeiras, 8 pedras).
3. Fabricar vara perto da bancada (6 madeiras, 8 fibras). Pescar perto da costa/cais e assar peixe na fogueira.
4. Construir casa (30 madeiras, 10 pedras, 10 fibras); descansar junto dela recupera saúde e gasta fome/água.
5. Construir cais na faixa costeira (20 madeiras, 10 fibras).
6. Construir barco junto ao cais (60 madeiras, 20 fibras, 8 metais), depois aproximar-se e escolher **Embarcar**.

Cocos recuperam água e fome; a nascente, marcada em azul no minimapa, recupera água. Após três minutos de adaptação, fome e sede começam a diminuir. Recursos naturais reaparecem após dez minutos de jogo; metal é finito. A ilha contém material suficiente para completar o barco. O save local conserva inventário, ferramentas, construções, posição e recursos coletados, com cópia de recuperação. A pausa e os painéis de inventário/construções suspendem sobrevivência e pesca. Saves v1 da v0.4 são lidos automaticamente pelo formato v2.

## Validação

- Importação/parsing Godot 4.6.1 e execução headless aprovados.
- **141/141 verificações nativas**: progressão até o barco, custos, restrições de construção, pesca/cozinha, sobrevivência, recursos, saves inválidos, backups, orientação da malha e multitoque.
- Renderização real com OpenGL Compatibility/Mesa e inspeção de capturas do menu, praia, construção, cavernas, nascente e acampamento.
- Auditoria de referências e pacote; ZIP testado após extração independente.
- Os scripts em `tests/` reproduzem as verificações. O workflow GitHub executa importação e testes a cada alteração; sua execução remota deve ser conferida separadamente.

**Novidades v0.4:** personagem articulado e ferramentas com ações próprias; áudio original de ambiente e interação; árvores de copa em grupos, samambaias, raízes e trilhas; casa/bancada detalhadas e cais transitável; descobertas únicas e diário persistente; HUD menor e mochila recolhida. No menu, Som permite silenciar e Visual permite escolher Completo/Leve.

A coleta só concede loot no contato da animação. O personagem aproxima-se do recurso; se houver bloqueio, aproxime-se por outro lado. Cancelar ação interrompe coleta/pesca. Ferramentas básicas são pagas e concedidas juntas no contato da fabricação; cancelar antes desse ponto não cobra recursos. Estruturas e vara são registradas ao confirmar; cancelar a animação de trabalho não desfaz a transação.

**Limites:** modelos procedurais ainda preliminares;  O APK v0.4.1 foi exportado, alinhado e assinado com a mesma chave da v0.4. Não houve teste desta revisão em aparelho Android, medição de FPS nele, geração de AAB ou validação para publicação. Áudio e mixagem ainda precisam de audição em hardware. O FPS do renderizador por software Linux não representa o desempenho do celular. Veja `docs/QA.md`, `docs/IMPROVEMENTS.md` e `docs/CONTINUITY.md`.


## Atualização v0.4.1

Mochila em grade com ícones originais, seleção de item e modelo real do personagem em viewport 3D. Cabeçalho, abas e × ficam fixos durante a rolagem. Troncos e pedras soltas na praia e em mais 90 pontos da ilha permitem começar sem ferramentas. Zoom de distância 12–48, persistido nas configurações; joystick de raio 88 (antes 66), área 220×220, afastado 100 px da borda esquerda e 54 px da inferior no canvas de referência.

Para exportar um APK, use `tools/android/build_android.sh` com Godot 4.6.1, templates correspondentes, Java 17 e Android SDK Build Tools 35.0.1. Informe os caminhos privados por `GODOT_BIN`, `ANDROID_SDK_ROOT`, `SURVIVOR_KEYSTORE` e `SURVIVOR_PASSWORD_FILE`. A chave e senha não pertencem ao repositório.

# GPT Survivor — Ilha: Último Voo

**Protótipo jogável v0.4.0 • Godot 4.x • 3D top-down • Android e PC**

Um sobrevivente de um acidente aéreo precisa explorar uma ilha tropical de aproximadamente 400 metros de diâmetro, montar seu acampamento e construir um barco para voltar para casa.

## Abrir no celular com Godot Android

1. Baixe e extraia `GPT_Survivor_Godot_v0_4_0.zip` em uma pasta acessível, por exemplo `Downloads/GPT_Survivor`.
2. Abra o Godot Android e escolha **Importar**. Selecione o arquivo `project.godot` da pasta extraída. Se a versão do editor permitir importar ZIP, também é possível selecionar o ZIP diretamente.
3. Abra o projeto. Use o celular na horizontal e toque em **▶ Executar projeto**.
4. No jogo, toque em **Nova sobrevivência** e depois **Acordar na praia**.

A primeira importação pode levar alguns segundos. O projeto gera as malhas localmente e não depende de downloads, APIs ou plugins. Recomenda-se Godot 4.4 ou superior; a validação desta entrega foi feita no Godot 4.6.1 Linux. Não há APK nesta versão: este é o projeto-fonte para o editor Godot.

## Controles

- **Celular:** Mochila mostra o inventário e o diário; joystick à esquerda; ação, pesca, construção e alimentação à direita. Use dois dedos para mover e interagir ao mesmo tempo. Arraste a lista de receitas para ver todos os itens; × fecha o painel.
- **PC:** WASD/setas para andar; E ação; B construção; F pesca/cancelar construção; H comer/beber; P salvar; Esc pausa/fechar; +/− aproximação da câmera.
- **Construções:** selecione uma receita, mova o personagem para posicionar a prévia verde, toque em Confirmar. A prévia vermelha informa o impedimento. Nenhum recurso é gasto até confirmar um local válido.

## Partida completa

1. Coletar madeira e cocos nos coqueiros, pedra nas rochas, fibra nas plantas e metal nos destroços/cavernas.
2. Construir fogueira (10 madeiras, 6 pedras) e bancada (16 madeiras, 8 pedras).
3. Fabricar vara perto da bancada (6 madeiras, 8 fibras). Pescar perto da costa/cais e assar peixe na fogueira.
4. Construir casa (30 madeiras, 10 pedras, 10 fibras); descansar junto dela recupera saúde e gasta fome/água.
5. Construir cais na faixa costeira (20 madeiras, 10 fibras).
6. Construir barco junto ao cais (60 madeiras, 20 fibras, 8 metais), depois aproximar-se e escolher **Embarcar**.

Cocos recuperam água e fome; a nascente, marcada em azul no minimapa, recupera água. Após três minutos de adaptação, fome e sede começam a diminuir. Recursos naturais reaparecem após dez minutos de jogo; metal é finito. A ilha contém material suficiente para completar o barco. O save local conserva inventário, ferramentas, construções, posição e recursos coletados, com cópia de recuperação. A pausa suspende sobrevivência e pesca.

## Validação

- Importação/parsing Godot 4.6.1 e execução headless aprovados.
- **101/101 verificações nativas**: progressão até o barco, custos, restrições de construção, pesca/cozinha, sobrevivência, recursos, saves inválidos, backups, orientação da malha e multitoque.
- Renderização real com OpenGL Compatibility/Mesa e inspeção de capturas do menu, praia, construção, cavernas, nascente e acampamento.
- Auditoria de referências e pacote; ZIP testado após extração independente.
- Os scripts em `tests/` reproduzem as verificações. O workflow GitHub executa importação e testes a cada alteração; sua execução remota deve ser conferida separadamente.

**Novidades v0.4:** personagem articulado e ferramentas com ações próprias; áudio original de ambiente e interação; árvores de copa em grupos, samambaias, raízes e trilhas; casa/bancada detalhadas e cais transitável; descobertas únicas e diário persistente; HUD menor e mochila recolhida. No menu, Som permite silenciar e Visual permite escolher Completo/Leve.

A coleta só concede loot no contato da animação. O personagem aproxima-se do recurso; se houver bloqueio, aproxime-se por outro lado. Cancelar ação interrompe coleta/pesca. Fabricação e construção são registradas ao confirmar; cancelar a animação de trabalho não desfaz o item já registrado.

**Limites:** modelos procedurais ainda preliminares;  Não houve teste no aparelho Android, medição de FPS nele, exportação APK/AAB ou validação para publicação. Áudio e mixagem ainda precisam de audição em hardware. O FPS do renderizador por software Linux não representa o desempenho do celular. Veja `docs/QA.md`, `docs/IMPROVEMENTS.md` e `docs/CONTINUITY.md`.

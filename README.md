# GPT Survivor — Ilha: Último Voo

**Protótipo de desenvolvimento v0.5.0 (código-fonte) • Godot 4.x • 3D top-down • Android e PC**

Um sobrevivente de um acidente aéreo precisa explorar uma ilha tropical de aproximadamente 400 metros de diâmetro, montar seu acampamento e construir um barco para voltar para casa.

## Atualização v0.5.0 — Acampamento e fuga por etapas

- **Fabricação por etapas:** corda = 1 fibra, produzida à mão; tábua = 2 madeiras, produzida próxima à bancada. A embarcação exige ambos e a pista `sail_diagram` encontrada na Caverna do Leste.
- **Construção:** botão **Girar 90°** durante a prévia e área de ocupação sinalizada no terreno. Em Mochila → Acampamento, **Mover** reposiciona construções sem cobrança adicional. Cais e barco permanecem fixos.
- **Acampamento:** baú de 100 itens com transferência de 1 unidade por toque (é necessário estar perto); cama com descanso; coletor com reservatório de até 12 unidades, enchendo durante chuvas periódicas. O jogador bebe água ao interagir.
- **Exploração:** registros adicionais nos destroços e na Caverna do Leste; esquema da vela obrigatório para concluir o barco; o diário registra essas descobertas.
- **Save:** versão 3 com migração de v1/v2, armazenamento, água armazenada e rotação. Modificações verificadas pelo workflow Godot 4.6.1 Linux. Sem APK v0.5 assinado nem teste físico de instalação/performance no Samsung Galaxy A35.

## Abrir no celular com Godot Android

1. Baixe e extraia `GPT_Survivor_Godot_v0_5_0.zip` em uma pasta acessível, por exemplo `Downloads/GPT_Survivor`.
2. Abra o Godot Android e escolha **Importar**. Selecione o arquivo `project.godot` da pasta extraída. Se a versão do editor permitir importar ZIP, também é possível selecionar o ZIP diretamente.
3. Abra o projeto. Use o celular na horizontal e toque em **▶ Executar projeto**.
4. No jogo, toque em **Nova sobrevivência** e depois **Acordar na praia**.

A primeira importação pode levar alguns segundos. O projeto gera as malhas localmente e não depende de downloads, APIs ou plugins. Recomenda-se Godot 4.4 ou superior; a validação desta entrega foi feita no Godot 4.6.1 Linux. O APK assinado desta branch ainda não foi gerado. Para atualizar sem desinstalar, a exportação Android precisa usar a mesma chave privada de assinatura da instalação anterior. O projeto pode ser aberto no editor Godot para desenvolvimento.

## Controles

- **Celular:** Mochila abre a grade de itens, o personagem, o diário, a nova aba **Equipar** e Construções; joystick maior à esquerda, afastado da borda; +/− abaixo do minimapa ajusta o zoom; ação, pesca, construção e alimentação à direita. Use dois dedos para mover e interagir ao mesmo tempo. Arraste a lista de receitas para ver todos os itens; × fecha o painel.
- **PC:** WASD/setas para andar; E ação; B construção; F pesca/cancelar construção; H comer/beber; P salvar; Esc pausa/fechar; +/− aproximação da câmera.
- **Construções:** selecione uma receita, mova o personagem para posicionar a prévia verde, use Girar 90° quando disponível e toque em Confirmar. A prévia vermelha informa o impedimento. Nenhum recurso é gasto até confirmar um local válido.

## Partida completa

1. Recolher troncos (3 madeiras cada), pedras soltas (2 pedras cada) e fibras à mão. Abra **Mochila → Construções**: machado de pedra = 3 madeiras + 2 pedras + 2 fibras; picareta = 3 madeiras + 3 pedras + 2 fibras; faca = 1 madeira + 2 pedras + 1 fibra. Sem bancada. Árvores/coqueiros exigem machado; rochas exigem picareta. Faca melhora a coleta de fibras de 5 para 8. Metal dos destroços é recuperado à mão.
2. Construir fogueira (10 madeiras, 6 pedras) e bancada (16 madeiras, 8 pedras).
3. Fabricar vara perto da bancada (6 madeiras, 8 fibras). Ela é equipada automaticamente na mão principal ao fabricar; se desequipar, abra **Mochila → Equipar** antes de pescar. Pesque na costa ou no cais, depois asse o peixe na fogueira.
4. Construir casa (30 madeiras, 10 pedras, 10 fibras); descansar junto dela recupera saúde e gasta fome/água.
5. Construir cais na faixa costeira (20 madeiras, 10 fibras).
6. Explore a Caverna do Leste e recupere o esquema da vela. Na bancada fabrique 10 tábuas (2 madeiras cada) e trance 10 cordas (1 fibra cada). Construa o barco com 40 madeiras, 10 fibras, 10 tábuas, 10 cordas e 8 metais, depois aproxime-se e escolha **Embarcar**.

Cocos recuperam água e fome; a nascente, marcada em azul no minimapa, recupera água. Após três minutos de adaptação, fome e sede começam a diminuir. Recursos naturais reaparecem após dez minutos de jogo; metal é finito. A ilha contém material suficiente para completar o barco. O save local conserva inventário, ferramentas, construções, posição e recursos coletados, com cópia de recuperação. A pausa e os painéis de inventário/construções suspendem sobrevivência e pesca. Saves v1/v2 são migrados automaticamente para o formato v3 (incluindo inventário e equipamentos).

## Validação

- Importação/parsing Godot 4.6.1 e execução headless aprovados.
- **verificações nativas automatizadas**: progressão até o barco, custos, restrições de construção, pesca/cozinha, sobrevivência, recursos, saves inválidos, backups, orientação da malha e multitoque.
- Renderização real com OpenGL Compatibility/Mesa e inspeção de capturas do menu, praia, construção, cavernas, nascente e acampamento.
- Auditoria de referências e pacote; ZIP testado após extração independente.
- Os scripts em `tests/` reproduzem as verificações. O workflow GitHub executa importação e testes a cada alteração; sua execução remota deve ser conferida separadamente.

**Novidades v0.4:** personagem articulado e ferramentas com ações próprias; áudio original de ambiente e interação; árvores de copa em grupos, samambaias, raízes e trilhas; casa/bancada detalhadas e cais transitável; descobertas únicas e diário persistente; HUD menor e mochila recolhida. No menu, Som permite silenciar e Visual permite escolher Completo/Leve.

A coleta só concede loot no contato da animação. O personagem aproxima-se do recurso; se houver bloqueio, aproxime-se por outro lado. Cancelar ação interrompe coleta/pesca. Ferramentas básicas são pagas e concedidas juntas no contato da fabricação; cancelar antes desse ponto não cobra recursos. Estruturas e vara são registradas ao confirmar; cancelar a animação de trabalho não desfaz a transação.

**Limites:** modelos procedurais ainda preliminares;  O APK v0.4.1 foi exportado, alinhado e assinado com a mesma chave da v0.4. Não houve teste desta revisão em aparelho Android, medição de FPS nele, geração de AAB ou validação para publicação. Áudio e mixagem ainda precisam de audição em hardware. O FPS do renderizador por software Linux não representa o desempenho do celular. Veja `docs/QA.md`, `docs/IMPROVEMENTS.md` e `docs/CONTINUITY.md`.


## Atualização v0.4.1

Mochila em grade com ícones originais, seleção de item e modelo real do personagem em viewport 3D. Cabeçalho, abas e × ficam fixos durante a rolagem. Troncos e pedras soltas na praia e em mais 90 pontos da ilha permitem começar sem ferramentas. Zoom de distância 12–48, persistido nas configurações; joystick de raio 88 (antes 66), área 220×220, afastado 100 px da borda esquerda e 54 px da inferior no canvas de referência.

Para exportar um APK, use `tools/android/build_android.sh` com Godot 4.6.1, templates correspondentes, Java 17 e Android SDK Build Tools 35.0.1. Informe os caminhos privados por `GODOT_BIN`, `ANDROID_SDK_ROOT`, `SURVIVOR_KEYSTORE` e `SURVIVOR_PASSWORD_FILE`. A chave e senha não pertencem ao repositório.


## Atualização v0.4.2 — Equipamento e pesca

O personagem agora possui **dois espaços persistentes de equipamento**: **Mão principal** (vara de pescar) e **Ferramenta** (faca, machado ou picareta). A aba **Mochila → Equipar** permite selecionar, trocar e desequipar ferramentas, mostra os dois espaços e utiliza os ícones do projeto. A aba Itens indica exatamente qual ferramenta está equipada.

- Árvore/coqueiro só podem ser colhidos com machado **equipado**; rochas só são mineradas com picareta **equipada**; a faca equipada rende mais fibras. Troncos e pedras soltas seguem coletáveis à mão.
- A vara pode ser fabricada na bancada e **entra automaticamente na Mão principal** para evitar o problema de pescar após fabricar; o botão PESCAR permanece visível e apresenta orientação se a vara estiver ausente ou desequipada.
- Os equipamentos são salvos juntamente com a partida. Saves v1 e saves v2 anteriores sem o campo `equipment` são migrados sem exigir que o jogador refaça seus itens; o save não exige desinstalar o aplicativo.
- Esta é uma atualização do **código**: a versão Android 0.4.2 ainda precisa de exportação, assinatura com a chave original e validação em dispositivo real. Não substituir o APK 0.4.1 por APK de outra chave se quiser conservar o progresso.

# GPT Survivor — Ilha: Último Voo

## v0.8 experimental — cavernas navegáveis (código-fonte, sem APK)

Foram adicionados **dois interiores tridimensionais jogáveis**, acessados pelo botão **Explorar** nas entradas da Caverna do Leste e da Gruta das Raízes. A câmera segue o personagem dentro de galerias com rochas, raízes, cristais, iluminação própria e obstáculos de circulação. O botão **Sair da caverna** devolve à superfície; o minimapa passa a exibir a planta interna e os suprimentos restantes.

Cada caverna possui **duas caixas de suprimentos investigáveis**, com materiais úteis à sobrevivência e ao barco. São recompensas únicas registradas em `discoveries`, evitando coleta duplicada. O save **mantém a versão 3** e também restaura a localização do personagem caso ele salve dentro de uma gruta. O mundo externo, a fauna, as ferramentas e o sistema de pesca existentes permanecem preservados.

**Limites:** esta é uma primeira implementação de exploração; ainda não há enigmas ambientais, combate dentro das grutas ou barco construído em etapas. As cavernas são cenários separados por transição, sem geometria subterrânea física conectada ao terreno. É necessário conferir a execução do CI e fazer QA visual/touch no Android antes de afirmar que estão prontas. **Não gerar nem exportar APK sem pedido explícito do usuário.**

## v0.7.2 — fauna com caça, alimentação e saves (código-fonte; sem APK)

Esta versão acrescenta **caranguejos coletáveis** na costa e **javalis caçáveis com lança de pedra equipada**. Os demais animais (tartarugas, aves e peixes 3D) permanecem sem captura; a pesca existente com vara não foi alterada. A lança é fabricada à mão com 4 madeiras, 2 pedras e 3 fibras e utiliza o espaço **Ferramenta** da aba Equipar. A coleta usa o mesmo fluxo de aproximação/animação/contato do sobrevivente e pode ser cancelada antes da recompensa.

Os caranguejos geram **caranguejo cru** e os javalis, **carne crua**. Na fogueira, a nova seção **Cozinha** permite assar os dois alimentos, além do peixe. Caranguejo assado recupera 26 de fome; carne assada recupera 48 de fome e 8 de saúde. Todos aparecem com ícones próprios na mochila e podem ser guardados no baú. A ação na fogueira escolhe peixe, caranguejo ou carne conforme ingredientes disponíveis, ou o jogador pode escolher diretamente na aba Construções.

Cada animal capturado reaparece após 900 segundos de tempo de jogo, e seu identificador/cooldown fica salvo no campo `harvested` do save v3. Saves anteriores carregam com zero unidades dos novos itens sem perda dos recursos antigos. Foram adicionados testes de receitas, ferramentas, respawn, duplicidade de loot, HUD, armazenamento e compatibilidade.

**Regra do projeto:** o workflow de exportação Android desta branch está em `workflow_dispatch` somente. Não compilar, assinar, exportar ou entregar APK até solicitação explícita. A importação Godot/testes nativos e a auditoria de fontes continuam no CI; não houve teste de APK nem medição real de FPS no celular. A v0.7.2 é uma branch experimental, não um release estável.


## Atualização v0.7.1 — portas e janelas funcionais (beta)

- **Abrigo modular expandido:** duas novas receitas repetíveis, **Porta de madeira** (3 tábuas, 2 madeiras e 1 corda) e **Parede com janela** (3 tábuas, 2 madeiras e 1 corda), após construir bancada e ao menos um piso.
- **Modelagem real no Godot:** porta de ripas com dobradiça e maçaneta, janela de moldura com travessas e peitoril. Ícones SVG inéditos são exibidos diretamente na aba Construções.
- **Passagem controlada:** interaja com a porta pelo botão **Explorar** para abrir/fechar. Aberta, a passagem fica livre; fechada, barra o personagem. A animação leva 0,32 segundos.
- **Encaixes revisados:** porta/janela/parede compartilham encaixes no perímetro de pisos, sem permitir sobreposições no mesmo encaixe; várias faces adjacentes podem ser construídas; telhado aceita suporte de qualquer parede.
- **Save preservado:** estado `door_open` validado no save v3, carregamento legado mantido, sem afetar os slots de equipamentos, coleta de recursos, vara de pesca ou condições da fuga.
- **Fauna da v0.7:** caranguejos, tartarugas, javalis, aves e peixes permanecem modelados e movimentando-se pelo cenário. Ainda não há caça/drops nem interiores navegáveis de cavernas.
- **Beta Android:** exportação ARM64 isolada com package `com.sergiomrge.gptsurvivor.beta.v071`. A assinatura de teste é diferente da versão estável; não reinstale por cima do jogo principal. Validar o resultado do GitHub Actions antes de instalar; desempenho e operação em telefone físico não foram medidos.


## Desenvolvimento v0.7.0 — fauna inicial (branch experimental)

Esta branch adiciona animais originais modelados diretamente com primitivas e malhas do Godot: caranguejos na areia, tartarugas costeiras, javalis no interior, aves sobre a ilha e cardumes costeiros. A população usa seed fixa e regiões de habitat; os animais vagueiam, descansam e fogem ao perceber o personagem. Atualização de movimento em passos de ~0,12 s e ocultação por distância; o modo Leve reduz a fauna visível.

A fauna é **visual/interativa apenas na reação à aproximação** nesta primeira etapa: ainda não há caça, alimentação dos animais, coleta de drops ou IA de perseguição. Essas mecânicas, os módulos avançados de construção, cavernas navegáveis e fuga cinematográfica continuam no roadmap. O save v3 não foi alterado, e os animais não persistem individualmente (são gerados deterministicamente). O APK v0.7 **não está pronto para instalação**. A execução dos testes no CI e validação em hardware Android devem ser verificadas antes de qualquer distribuição.


**Protótipo de desenvolvimento v0.6.0 (código-fonte) • Godot 4.x • 3D top-down • Android e PC**

Um sobrevivente de um acidente aéreo precisa explorar uma ilha tropical de aproximadamente 400 metros de diâmetro, montar seu acampamento e construir um barco para voltar para casa.

## Atualização v0.6.0 — Clima real e primeiros módulos de construção

- **Atmosfera:** ciclo de luz com amanhecer/entardecer, noite mais escura, chuva tropical e pico de tempestade, com partículas limitadas pelo modo gráfico.
- **Materiais vivos:** vento nas folhas e grama, mar com ondas intensificadas pela tempestade, brilho/escurecimento do solo molhado, luz ambiente sensível à nebulosidade.
- **Sobrevivência:** o coletor de água usa **a mesma curva de chuva** do clima visual; sem chuva, não produz água; o ciclo é determinístico e preserva os saves anteriores.
- **Personagem:** corrida opcional com botão **Correr/Andar** junto ao analógico e passos/postura específicos; o botão não interfere na pesca, coleta ou multitoque.
- **Construção modular inicial:** **Piso modular, Parede modular e Telhado modular**. São fabricáveis repetidas vezes pela aba **Mochila → Construções**, com encaixe espacial de 3,2 m, rotação de 90 graus, paredes na borda de pisos, telhado dependente de piso e parede, verificação de colisão e persistência.
- **Qualidade:** modo Leve reduz emissão de partículas de chuva de 280 para 90 e conserva as otimizações anteriores de sombras e vegetação.
- **Teste:** 182/182 verificações nativas da v0.6 passaram no Godot 4.6.1 Linux, incluindo esquemas de clima, suporte dos módulos, salvamento e botões touch. Sem medição de FPS nem inspeção visual no Android físico.
- **Beta independente:** o pipeline Android utiliza pacote `com.sergiomrge.gptsurvivor.beta.v06` e assinatura de teste temporária para evitar sobrescrever a instalação estável e o beta anterior. Para atualizar a versão instalada com mesmo ID, será necessária a chave privada original.

**Ainda não concluído:** reformulação integral da modelagem e materiais, animais com IA, interiores completos/cavernas exploráveis, portas/janelas, barco montado visualmente em etapas e otimização medida a 60 FPS no aparelho. Consulte `docs/ROADMAP_v06.md`.

## Atualização v0.5.0 — Acampamento e fuga por etapas

- **Fabricação por etapas:** corda = 1 fibra, produzida à mão; tábua = 2 madeiras, produzida próxima à bancada. A embarcação exige ambos e a pista `sail_diagram` encontrada na Caverna do Leste.
- **Construção:** botão **Girar 90°** durante a prévia e área de ocupação sinalizada no terreno. Em Mochila → Acampamento, **Mover** reposiciona construções sem cobrança adicional. Cais e barco permanecem fixos.
- **Acampamento:** baú de 100 itens com transferência de 1 unidade por toque (é necessário estar perto); cama com descanso; coletor com reservatório de até 12 unidades, enchendo durante chuvas periódicas. O jogador bebe água ao interagir.
- **Exploração:** registros adicionais nos destroços e na Caverna do Leste; esquema da vela obrigatório para concluir o barco; o diário registra essas descobertas.
- **Save:** versão 3 com migração de v1/v2, armazenamento, água armazenada e rotação. Modificações verificadas pelo workflow Godot 4.6.1 Linux. Sem APK v0.5 assinado nem teste físico de instalação/performance no Samsung Galaxy A35.

## Abrir no celular com Godot Android

1. Baixe e extraia `GPT_Survivor_Godot_v0_6_0.zip` em uma pasta acessível, por exemplo `Downloads/GPT_Survivor`.
2. Abra o Godot Android e escolha **Importar**. Selecione o arquivo `project.godot` da pasta extraída. Se a versão do editor permitir importar ZIP, também é possível selecionar o ZIP diretamente.
3. Abra o projeto. Use o celular na horizontal e toque em **▶ Executar projeto**.
4. No jogo, toque em **Nova sobrevivência** e depois **Acordar na praia**.

A primeira importação pode levar alguns segundos. O projeto gera as malhas localmente e não depende de downloads, APIs ou plugins. Recomenda-se Godot 4.4 ou superior; a validação desta entrega foi feita no Godot 4.6.1 Linux. A exportação Android beta da v0.6 é realizada pelo workflow Build Android Beta APK da branch; confira a execução e o artefato publicado antes de instalar. Para atualizar sem desinstalar, a exportação Android precisa usar a mesma chave privada de assinatura da instalação anterior. O projeto pode ser aberto no editor Godot para desenvolvimento.

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

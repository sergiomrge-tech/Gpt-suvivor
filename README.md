# GPT Survivor — Ilha: Último Voo

## v1.1.0 — Ilha aprimorada + Inventário visual e funcional (código-fonte, sem APK)

**Identidade do novo inventário**: interface do jogo em tons de madeira escura e bronze envelhecido, títulos em fonte serifada (Noto Serif/Georgia/serif por disponibilidade no sistema), bordas finas douradas, painéis retangulares, ícones grandes e leitura de quantidades. O mesmo tema é utilizado nas quatro seções e nos botões de abertura e fechamento do inventário.

- **MOCHILA**: grade 5×N com os 21 recursos/ferramentas existentes, seleção destacada, descrição e quantidade, prévia 3D real do sobrevivente, resumo de materiais e acesso a alimentos.
- **EQUIPAMENTOS**: duas áreas físicas distintas (mão principal e ferramenta), ícones dos itens equipados, ações Equipar/Desequipar e Comparar. O painel compara o item escolhido com o atualmente equipado, usando rendimento real do machado (8→12 madeiras) e picareta (6→9 pedras), sem atributos fictícios.
- **CONSTRUÇÕES**: categorias de acampamento, casa modular e estruturas reforçadas, com painel adicional para administrar o acampamento. Exibe materiais possuídos / exigidos, bloqueios de pesquisa e progresso de preparação.
- **RECEITAS**: somente ferramentas básicas e reforçadas, corda/tábua e receitas de cozinha, com situações **DESBLOQUEADA/BLOQUEADA/CONCLUÍDO**, recurso insuficiente em vermelho e suficiente em verde, indicadores visuais de progresso.
- **ATALHOS DE FERRAMENTAS**: cinco botões físicos dentro da HUD mobile (machado, picareta, faca, lança, vara). Tocá-los troca o equipamento salvo; opções ainda não fabricadas ficam desativadas; ferramentas reforçadas ocupam automaticamente o atalho correspondente quando possuídas. No PC funcionam também as teclas 1–5. O uso da ferramenta continua respeitando as regras reais de equipamentos, caça, coleta e pesca.
- **QUALIDADE**: navegação touch, bloqueio de botões de fundo durante modais, ajustes responsivos para telas horizontais, teste nativo no Godot 4.6.1, e workflow adicional que tira capturas **reais do jogo renderizado** para auditoria visual.

**Compatibilidade:** preservados save versão 3, toda exploração anterior, caça, barco em etapas, construção modular, cavernas, clima, áudio confortável e modo Leve/Completo. Não há APK nesta atualização; a exportação Android continua fora do workflow de validação de fonte. **A referência visual fornecida pelo usuário é o alvo de fidelidade; igualdade pixel a pixel requer comparar as capturas reais com a imagem fornecida, sem afirmar equivalência não verificada.**


## v1.0.0 — Construção reforçada, revisão de progressão e APK beta Android

A versão 1.0 mantém o ciclo de sobrevivência em ilha 3D de todas as versões anteriores: coleta com ferramentas equipadas, pesca funcional, caça de animais, cozinhar alimentos, água/sede, clima, inventário, baú, fabricação, dois sistemas de cavernas com relíquias, oficina nível 2 e barco construído em cinco estágios para fuga.

**Nova evolução de construção (nível 2):** a **parede reforçada** é construída na grade modular de 3,2 m, requer bancada aprimorada + piso, e custa 3 tábuas, 4 pedras e 1 metal. Usa modelo 3D original com base de pedra, tirantes de metal, vigas e tábuas escuras. O **telhado reforçado**, que exige uma parede reforçada e bancada aprimorada, custa 5 tábuas, 2 pedras e 1 metal; seu modelo 3D usa estrutura de madeira, telhas cinza e rebites metálicos. Ambas preservam save v3, encaixes, rotação e colisões. Estão em seção própria na Mochila → Construções.

**Polimento já incluído:** passos suaves e baixos com filtragem de agudos, câmera com zoom, controle analógico ampliado, menus de equipamentos, clima dinâmico, 3D procedural, modos visuais Leve/Completo, progressão de ferramentas e indicação de materiais para cada etapa do barco.

**APK de teste:** exportação Android ARM64 com chave de depuração beta e identificador separado `com.sergiomrge.gptsurvivor.beta.v100`, para não sobrescrever versões anteriores. O pacote é destinado a teste fechado no aparelho, **não** a Play Store; pode ser necessário desinstalar uma variante beta caso use outro certificado. O código-fonte segue disponível no repositório. A validação pelo CI não substitui testes reais de áudio, toque, desempenho e estabilidade no telefone. 

**Estado:** marco de código 1.0 e APK beta não são afirmação de homologação de loja, 60 FPS constante ou acabamento artístico final.


## v0.9.0 — passos mais suaves + barco construído em cinco etapas (código-fonte, SEM APK)

### Áudio: passos confortáveis e baixos
- O áudio de passos existentes em areia, grama e madeira agora é tratado no Godot na inicialização com **filtro passa-baixas**, rampa de entrada/saída de 10/55 ms, amplitude mais suave e **volume próprio de -23 dB**, independente do volume dos demais efeitos (que permanecem em -9 dB).
- O processamento acontece **apenas uma vez no carregamento dos WAVs**, em cópias privadas de `AudioStreamWAV`; os arquivos originais não são sobrescritos. Pequenas variações de pitch (±3,5%) tornam as pisadas menos repetitivas.
- O teste nativo verifica PCM suavizado, continuidade nas extremidades e ausência de alterações no áudio WAV original. **O resultado ainda precisa ser ouvido no Android físico** para aferir se o volume e o timbre agradam.

### Barco de fuga por etapas
- O barco agora é montado junto ao cais em **5 fases**, com modelo 3D próprio para cada uma: (1) **Quilha**, (2) **Casco**, (3) **Convés**, (4) **Mastro**, (5) **Vela e leme**. Cada fase acrescenta peças visíveis em vez de exibir o barco inteiro antes da conclusão. As malhas das peças de cada etapa são fundidas em uma malha estática para reduzir draw calls no celular.
- A mochila cria primeiro a quilha: **16 madeiras, 2 tábuas e 1 corda**. Use **Explorar** próximo do barco incompleto para trabalhar nas fases seguintes:
  - Casco: **12 madeiras + 3 tábuas + 2 cordas**.
  - Convés: **4 madeiras + 3 tábuas + 2 cordas**.
  - Mastro: **8 madeiras + 1 tábua + 2 cordas**.
  - Vela e leme: **10 fibras + 1 tábua + 3 cordas + 8 metais**.
- Cada etapa é cobrada **somente no contato da animação de trabalho**; cancelar antes desse contato deixa itens e progresso intactos. O HUD mostra a próxima etapa e o painel Acampamento mostra os custos e quantidades disponíveis.
- **Não é possível embarcar** até finalizar as 5 etapas. O save mantém **versão 3** com campo opcional `stage` no barco. Barcos antigos sem esse campo continuam sendo reconhecidos como **já concluídos**; progresso parcial é salvo e restaurado.
- A quantidade total de materiais para o barco permanece a mesma da receita antiga (40 madeiras, 10 tábuas, 10 cordas, 10 fibras e 8 metais), apenas distribuída entre as cinco fases.
- Testes nativos: som modificado em memória, fases do barco, custo exato, cancelamento, colisão/posição perto do cais, modelo 3D com mastro tardio, não embarcar cedo, salvamento de estágio e restauração de saves antigos.

**Limites conhecidos:** ainda falta ouvir o novo áudio e testar o toque/FPS em Android físico; a fuga continua com animação de partida curta, sem pilotagem marítima. Melhorias estruturais do abrigo (paredes reforçadas, etc.) permanecem futuras. Os testes de Godot e auditorias são executados no GitHub Actions, mas não equivalem à homologação física.

**Preferência do usuário (13/10/2026): NÃO criar, compilar, assinar, entregar ou disparar APK até pedido explícito.** O workflow Android continua **manual (`workflow_dispatch`)**. Só este código-fonte e os testes são publicados no GitHub.


## v0.8.0 — cavernas, enigmas e oficina nível 2 (código-fonte, sem APK)

**Progressão survival craft original**, combinando boas práticas de evolução de bancadas, ferramentas por categorias, recursos raros e exploração de jogos de sobrevivência, sem utilizar assets ou receitas de terceiros:

- **Caverna do Leste e Gruta das raízes**: interiores realmente navegáveis, rochas, raízes e cristais modelados no projeto, iluminação e minimapa próprios, portais de entrada/saída, quatro caixas exclusivas com suprimentos, save dentro das cavernas preservado.
- **Enigmas ambientais**: cada caverna tem dois selos de pedra. Ative ambos pelo botão Explorar, então alcance o relicário. Recompensas únicas salvas em `discoveries`; coletar duas vezes não gera novos recursos. O minimapa diferencia selos e relicários; o Diário mostra selos 0–2/2 e status da pesquisa.
- **Cristais de cavernas**: recurso raro (`cave_crystal`) disponível nos relicários, com ícone próprio, inventário, baú e migração segura dos saves anteriores.
- **Pesquisa e estações por nível**: abrir o Relicário do Leste desbloqueia a receita da **Estação de aprimoramento**. Construí-la perto da bancada custa 6 madeiras, 4 tábuas, 2 metais e 1 cristal; seu modelo 3D apresenta prateleiras, instrumentos e cristal. A oficina libera uma nova categoria de ferramentas.
- **Equipamentos nível 2**: machado reforçado e picareta reforçada usam 3 metais, 2 tábuas e 1 corda cada e exigem a ferramenta de pedra correspondente. Fabricados perto da nova estação, são automaticamente equipados no slot Ferramenta, com aparências de metal próprias na mão do sobrevivente. Cortar árvore/coqueiro rende **12 madeiras em vez de 8**; minerar rocha rende **9 pedras em vez de 6**. Receita e pagamento são confirmados ao contato da animação, sem cobrança antecipada de trabalho cancelado.
- **Compatibilidade**: mantido save v3, inventário e equipamento antigo, pesca com vara, caça, clima, construções modulares e fuga por barco. O teste automatizado completo do Godot está disponível no GitHub Actions.

**Ainda pendente para versões futuras**: barcos montados etapa a etapa, interiores subterrâneos integrados continuamente à malha do terreno, enigmas mais sofisticados, melhoria da casa de madeira para outros materiais, inspeção visual real e medição de FPS no Android. A versão 0.8 é um marco de desenvolvimento validado por CI, não uma homologação comercial.

**Regra do projeto:** não gerar, assinar, exportar ou entregar APK, nem disparar workflow Android, até solicitação explícita do usuário. Builds de teste do Godot e publicações de código-fonte no GitHub estão autorizados.


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

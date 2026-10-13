## Atualização de integração CC0 v2.1 — destroços e bancada

- O local do acidente agora inclui quatro modelos PBR/GLTF já licenciados CC0: caixa militar de madeira, caixa alternativa, balde e cadeira de acampamento. Cada objeto é ancorado à altura real do terreno e limitado a uma área curta ao redor da fuselagem importada.
- A bancada de carpintaria recebe uma segunda variante real de caixa como acessório visual. **Não são recursos gratuitos, loot, receitas ou construções adicionais**: custo, interação, posição do avião, progresso e save permanecem iguais.
- Os arquivos originais estão em `assets/survival_props/models/`. A atribuição e os endereços de origem permanecem em `assets/survival_props/CATALOG.json`; no projeto Godot estão referenciados em `SurvivorRealWorldAssets`.
- A suíte nativa `tests/test_world_cc0.gd` verifica as quatro peças e a bancada. As capturas da execução incluem `15_crash_original_supplies_CC0.png` e `16_cc0_shelter_and_camp.png` (produzidas apenas pela execução real do Godot).
- Continuação experimental em branch; não gerar APK nesta revisão nem declarar FPS Android sem medição no aparelho.

# GPT Survivor — Ilha: Último Voo

## v1.8.0 — Silhueta orgânica e materiais separados do herói (fonte Godot; SEM APK)

- **Correção de close-up do rosto**: removidos volumes esféricos salientes do nariz; substituído por contorno contínuo de ponte/ponta nasal e olhos menores parcialmente recuados, com delineamento de pálpebras. Trata-se de uma melhora de modelagem real, ainda não de um rosto humano de produção.
- **Geometria anatômica mais contínua**: `SurvivorHeroGeometry.resample_profile` interpola os perfis existentes com Catmull–Rom controlado, criando novas faixas suaves de geometria em tórax, cabeça e membros. Os extremos e a altura de cada perfil são preservados, evitando inversões e quebras entre juntas.
- **Proporções corrigidas no jogo**: tórax mais estreito, cintura de transição contínua, linha dos ombros menos exagerada e contorno de crânio/mandíbula refinado após inspeção das capturas nativas anteriores. Mantidos todos os pivôs de equipamentos, braços, pescoço, ferramentas e animações.
- **Marcha com apoio visual**: pé de balanço recebe pequena elevação assimétrica, rolagem de tornozelo mais suave, contrarrotação de ombro/quadril e cotovelos em fases distintas. A física, velocidade, colisão e som dos passos permanecem iguais; ações continuam com os mesmos encaixes.
- **Cabelo não é couro**: a malha mesclada preserva agora `UV2.x=5` para tecido, `6` para pele, `7` para couro e `8` para cabelo/sobrancelhas. A nova resposta procedural de fios evita o brilho/material de couro aplicado anteriormente ao cabelo, sem adicionar texturas externas ou novas APIs.
- **Testes e capturas nativas**: validação de monotonicidade, radii e extremidades dos novos perfis, famílias de pele/cabelo, contorno do corpo e passada alternada. `visual_hero_v18.yml` captura 12 frames REAIS Godot 4.6.1: vistas de jogo, ação de machado, pesca, frente/perfil detalhados, botas, marcha em fase oposta e reação dos materiais sob chuva.
- **Limitação importante**: esta é uma revisão real de geometria procedural, não a substituição por um humano fotorrealista. O próximo salto de qualidade exige modelagem humana autoral com retopologia, skinning de esqueleto, materiais PBR (albedo/normal/roughness) e animação produzida, com LOD e teste de desempenho em Android físico. Nenhum APK foi gerado.

## v1.7.0 — Herói 3D: tornozelos articulados, botas orgânicas, mãos e materiais (fonte Godot; SEM APK)

- **Auditoria extra de câmera lateral**: a renderização ampliada revelou sola e volume dos calçados exagerados e mangas e punhos cilíndricos. A malha dos pés foi encurtada/afinada sem alterar o pivô do tornozelo, e as mangas e palmas foram suavizadas.
- **Proporções revistas após capturas reais**: cabeça visualmente menor, ombros e braços mais esguios, pernas prolongadas sem deslocar a sola do chão e olhos/nariz menos exagerados. O próprio render evidenciou aparência de boneco na primeira revisão, então essa correção integra a mesma v1.7.
- **Pés e caminhada:** removidos os antigos sapatos em caixas retangulares. Cada canela possui agora um pivô de tornozelo independente; botas criadas em 3D com peito do pé arredondado, camada de solado, cano e cadarços, e correção heel-to-toe em marcha. Os pivôs são exclusivamente visuais, sem mudar a colisão.
- **Silhueta e roupas:** gola e abertura da camisa, pregas assimétricas, costuras finas e alças do equipamento. Palma das mãos agora tem um volume contínuo, polegar e dedos, em vez da antiga esfera simples. Revisão discreta das maçãs do rosto, sobrancelhas, borda de cabelo e nariz.
- **Materiais:** a malha combinada mantém tratamentos próprios para tecido (UV2 família 5), pele (6) e couro gasto (7), com microvariação procedural de relevo/cor e resposta à umidade. Nenhuma textura externa ou licença de terceiros foi adicionada.
- **Jogabilidade intacta:** rotação e pivôs originais de braços, corpo e ferramentas mantidos. Corte, mineração, pesca, machado, picareta, lança, coleta e interação usam os encaixes anteriores; saves versão 3 e mundo v1.6 não mudam.
- **Mobile:** botas idênticas compartilham o mesmo mesh cache; os segmentos de membros são fundidos para reduzir materiais/draw calls. O sistema preserva a câmera móvel e o preset gráfico Leve/Completo, mas desempenho real em Android ainda precisa ser medido.
- **Validação:** testes nativos para malhas das botas, material de couro, pivôs dos pés, marcha e fixação de ferramentas. Workflow adicional realiza dez capturas reais do framebuffer Godot (frente, perfil, costas, caminhada, ação de machado, pesca, escala mobile e três planos de inspeção em câmera 3D real).
- **Limitação artística:** refinamento real em geometria procedural, não um personagem humano fotorrealista de produção. O próximo salto requer malha humana esculpida, rig/skinning completo, texturas PBR detalhadas, animações capturadas ou produzidas, LODs e inspeção no dispositivo. Sem APK por decisão do projeto.

## v1.6.0 — Costa orgânica, sub-bosque e novos materiais 3D (somente código Godot, SEM APK)

**Refinamento efetivo no mapa 3D existente**:
- Acrescentadas duas famílias originais de geometrias por `SurvivorBiomeProps`: **troncos desgastados trazidos pela maré** (volumes irregulares, fibras e galhos) e **raízes superficiais com musgo** no sub-bosque úmido. O segundo conjunto usa sua própria semente, preservando integralmente a distribuição da v1.5. Nenhum desses elementos dá loot nem cria colisão.
- **Coqueiros remodelados** com onze frondes arqueadas e folíolos estreitos individuais, gerando sombra/silhueta mais natural. As malhas continuam unidas e cacheadas por variante, sem mudar ID, rendimento ou raio de coleta dos recursos.
- **Materiais refinados**: solo tropical com húmus e manchas orgânicas, rochas com bandas minerais, cascas com fissuras longitudinais e granitos com veios discretos. Os shaders reutilizam as mesmas amostras de textura, sem novas dependências externas.
- **Preservação**: geometria do terreno, elevações, coordenadas de recursos, costa, construções, trilhas, receitas, inventário e `SAVE_VERSION=3` seguem inalterados. Cenas decorativas são agrupadas por `MultiMesh`, têm distância máxima de desenho menor e continuam reduzidas no modo Leve.
- **Visibilidade do personagem**: corrigida a interferência de folhas de coqueiro que apareciam enormes em primeiro plano nos screenshots de teste. O material agora usa o eixo real câmera→herói para reduzir temporariamente a opacidade somente da vegetação que oculta a jogabilidade.
- **Capturas verdadeiras**: workflow de oito imagens do próprio Godot, incluindo duas novas áreas de madeira costeira e musgo/raízes; testes nativos abrangem as cinco famílias de habitats. Ainda é necessária avaliação artística humana da captura, além de testes de FPS, toque e temperatura em Android real. Estes procedimentos não afirmam fotorrealismo AAA.
- **Sem APK**: a exportação Android permanece exclusivamente manual, conforme preferência do projeto.

## v1.5.0 — Refinamento geométrico da ilha e habitats tropicais (código Godot; SEM APK)

- **Vegetação em camadas**: acrescentados juncos de dunas e samambaias de sub-bosque, ambos com malhas originais de folhas curvas, coloração por instância, vento e resposta à chuva. Distribuição fixa por altura e cobertura vegetal, evitando recursos, trilhas, construções e marcos.
- **Geologia real no cenário**: fragmentos de rocha multifacetados em encostas e áreas de mata, com posicionamento baseado na inclinação da elevação real. Como são pequenos elementos decorativos, não alteram colisão, lógica de coleta ou locais de construção.
- **Copas de árvores reconstruídas**: antigas massas esféricas substituídas por troncos afunilados, galhos distribuídos em alturas diferentes e centenas de folhas 3D por árvore. Toda a malha é reunida/cacheada para reduzir draw calls; madeira e radius de coleta não mudam.
- **Praias e mar**: faixa de areia úmida com variação lenta do avanço das ondas, ripples orientados pelo vento, exposição geológica localizada e água tropical com bancos de areia, arrebentação irregular e reflexos ajustados. Nenhuma mudança na elevação, costa navegável, posicionamento dos recifes ou progressão.
- **Android**: instanciamento espacial por MultiMesh e corte por distância; qualidade Leve limita densidade da vegetação nova. O efeito de microrrelevo v1.4 permanece seletivo no modo Completo.
- **Verificação**: testes nativos verificam famílias de habitats, lotes, exclusões nas trilhas, efeito do clima, versão de save e geometria ramificada das árvores. Novo fluxo `visual_biomes_v15.yml` captura seis frames reais Godot da praia, areia, sub-bosque, região alta, chuva e qualidade leve.
- **Limite visual**: mais geometria e materiais melhoram a naturalidade, mas esta versão não representa terreno ou flora fotorrealistas de produção. Texturas físicas de alta qualidade, fotogrametria, escultura e otimização em dispositivos reais ainda são trabalhos seguintes. Nem o FPS Android nem a qualidade fotográfica são afirmados sem teste. Nenhum APK será criado sem solicitação.

## v1.4.0 — Primeira etapa de anatomia 3D e materiais realistas (fonte Godot; SEM APK)

- **Personagem remodelado em código 3D real**: novo gerador de malhas por perfis contínuos com normais suavizadas, substituindo o antigo corpo baseado quase exclusivamente em caixas/esferas/cilindros. Tórax afunilado com ombros e cintura, cabeça com maxilar e crânio próprios, braços e pernas afunilados, botas, mochila mais plana e detalhes discretos de roupa/rosto. Mantidos os mesmos pontos de articulação e encaixes de ferramentas.
- **Animações físicas aprimoradas**: deslocamento de ombros/quadris, inclinação na corrida, respiração discreta em repouso e contrarrotação da cabeça para reduzir a sensação de robô. Continuam funcionais corte, mineração, pesca, caça, craft e repouso.
- **Materiais mais naturais**: separação por vértice de pele e tecido na malha combinada, com microvariação de aspereza/cor e malha fundida para poupar draw calls.
- **Praia/floresta**: rugosidade de areia molhada, solo/granito e microrrelevo por normal em shader; as duas leituras adicionais da textura são aplicadas somente no modo visual **Completo**. O modo **Leve** desliga esse efeito.
- **Qualidade e continuidade**: saves versão 3, jogabilidade, inventário premium, cavernas, barco e progressão da v1.3 preservados. Incluídos testes para malhas/normais, materiais e alternância de modo visual e workflow que tira capturas de framebuffer do Godot original.
- **Limite artístico**: esta é uma melhoria geométrica/procedural concreta, **não** um personagem fotorrealista final. Para atingir qualidade extrema de produção ainda são necessárias escultura 3D, UV, texturas PBR (albedo, normal, roughness), cabelo/vestuário, rig/skinning e animações de produção com LODs para Android. Não há validação visual no aparelho, benchmark 60 FPS nem APK nesta etapa.

## v1.3.0 — Ventilação perigosa nas cavernas e painel de navegação (código-fonte, sem APK)

- **Vapores com ritmo legível**: as zonas minerais profundas de ambas as cavernas passam por 4,5 segundos de gás ativo em ciclos de 8 segundos. Uma luz localizada sem sombras móveis diferencia o período de risco da pausa segura; o jogador pode aguardar ou contornar. O período é reproduzível usando o tempo da partida e não exige alterar o save v3.
- **Barco mais orgânico**: uma oscilação suave de balanço e arfagem acompanha o avanço, sem perder os controles da versão anterior.
- **HUD marítimo aprimorado**: mostra integridade do casco em uma barra própria, distância em metros até o próximo recife e dica de manobra/posição. Os botões amplos para bombordo e estibordo continuam separados dos controles de exploração.
- **Regressões**: validação Godot 4.6.1 no GitHub Actions, com 445/445 verificações nativas antes do ajuste final de CI e 4 capturas reais automatizadas de ambientes/viagem. Permanecem pendentes teste manual touch no Android, FPS, áudio por audição e comparação visual contra referência original. Sem gerar APK.


## v1.2.0 — Cavernas profundas, natureza sonora e fuga marítima jogável (código, SEM APK)

### 5. Exploração das cavernas
- As duas cavernas existentes conservam suas entradas e coordenadas de saves antigos e agora têm **galerias realmente conectadas** ao fundo, com chão, paredes, arcos minerais, raízes e pontos de luz próprios (renderização 3D real pelo Godot, câmera top-down).
- **Dois esconderijos adicionais**, quatro veios cristalinos que **exigem picareta reforçada equipada** para minerar e somam recompensas raras e materiais para o acampamento. Recursos coletados uma vez só são registrados em `discoveries` no save v3.
- Cada galeria funda adiciona dois ecos ambientais que desbloqueiam um relicário secreto, com **duas recompensas extras de cristais** em cada local. Os dois relicários antigos permanecem independentes e preservados.
- Mineral de vapor colorido sinaliza uma zona perigosa no meio do corredor profundo; causa dano gradual somente ao permanecer sobre a zona, sendo possível contorná-la. O diário registra a progressão de ecos e câmaras.

### 7. Áudio ambiental dinâmico
- Ondas do mar, vento e fogueira existentes preservados; **novos pássaros durante o dia**, **insetos noturnos**, **chuva suave dinâmica**, **gotejamento em cavernas**.
- Os quatro novos sons são sintetizados de forma determinística no Godot, em PCM 16-bit mono com loops compactos; nenhum áudio externo comercial ou sem licença foi incluído.
- Através do menu, controle **três volumes independentes**: ambiente, efeitos (ferramentas/interações) e passos. Seus níveis ficam registrados em `user://visual.cfg`. Os passos seguem suaves e baixos, filtrados como na v0.9.

### 8. Uma fuga de verdade, controlável
- Ao terminar o barco de cinco etapas, prepare sua travessia com **2 cocos, 1 peixe assado, 2 cordas e 1 tábua**. São consumidos uma única vez, com marcador persistente e verificável no save v3.
- Toque **Embarcar** novamente para iniciar a viagem. O barco avança como objeto real pelo mar 3D, com câmera que o acompanha, barra de viagem e integridade do casco.
- Dois botões amplos no celular (**bombordo/estibordo**) ou as teclas A/D e setas no PC ajustam a rota lateral. Três recifes com modelos físicos punem colisões em 38 pontos de casco por impacto.
- **A vitória só ocorre ao cruzar de fato o canal seguro**, não imediatamente ao clicar em Embarcar. Se o casco quebrar, o barco volta ao cais para nova tentativa; não desconta suprimentos novamente.
- Regras antigas de coleta, fauna, pesca, inventário, construções modulares, ruínas, clima e barco por etapas são preservadas.

### Validação e limites
O projeto tem testes automatizados Godot headless para progressão, veios raros, save/load, som, tempo, embarque, perda de casco, nova tentativa e vitória real. Ainda são necessárias audição e análise visual/FPS no dispositivo Android. Esta é uma versão-fonte, não um APK nem uma versão homologada para loja. O workflow Android continua separado e não deve rodar sem pedido explícito do usuário.


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

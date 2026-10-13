# GPT Survivor — Roadmap executável v0.6 → v1.0

## Restrições fixas
- Engine Godot 4.6.1+; Android ARM64 com interface touch em modo horizontal.
- Preservar save, código de pesca/inventário/equipamentos e destino final: escapar da ilha por barco.
- Arte produzida dentro do projeto (não substituir pelo envio de imagens conceituais).
- Meta 60 FPS no aparelho, com qualidade Leve/Completo e medições reais antes de qualquer afirmação de desempenho.
- Branches de desenvolvimento primeiro, CI 100%, APK beta separado; merge somente quando houver reconciliação com branches existentes.
- Chave de assinatura original nunca exposta em GitHub.

## v0.6.0 — Mundo vivo: primeiro marco concluído no código
- [x] Ciclo contínuo de amanhecer, dia, crepúsculo e noite.
- [x] Clima compartilhado entre física da coleta de água e visuais.
- [x] Chuva, pico de temporal, rajadas de vento, alteração de luz ambiente.
- [x] Solo e vegetação molhados, oceano mais agitado, vegetação ondulando.
- [x] Emissão de chuva menor no modo Leve.
- [x] Corrida com controle touch separado e animações de passos, joelhos, braços e torso.
- [x] Três peças modulares fabricáveis e persistentes: piso, parede e cobertura.
- [x] Snap de 3,2m; rotação de 90°; parede exige piso, cobertura exige parede + piso.
- [x] Preservação de itens da v0.5 e das versões mais antigas.
- [x] 182 verificações automatizadas headless Godot.
- [ ] Validar visual e FPS no celular Android físico.

## v0.7 — Construção + fauna
- Sistema modular completo: portas, janelas, suportes, paredes de canto, telhado com orientação, decoração e variantes.
- Colocação/remoção por instância e reembolso seguro, sem retirar outra peça de mesma categoria.
- Caranguejos próximos à costa, aves em bandos, javalis na mata, tartarugas costeiras e peixes visíveis.
- IA de estados simples (vaguear, fugir, procurar alimento, descansar) em atualização com LOD espacial.
- Sons e drops próprios; materiais/receitas conectados à sobrevivência.
- Teste de save, toque, colisões e orçamentos de CPU/GPU.

## v0.7.2 — Loop inicial de fauna e cozinha

- [x] Coleta de caranguejos nas praias e caça de javalis exigindo lança de pedra equipada.
- [x] Novos alimentos crus e assados na fogueira; recuperação de fome/saúde; mochila/baú.
- [x] Reaparecimento em tempo de jogo e persistência de fauna coletada no save v3.
- [x] Pipeline APK alterado para disparo exclusivamente manual após pedido do usuário.
- [ ] IA avançada com procura real de alimentos, sons exclusivos, reação a ferimentos e animações corporais detalhadas.
- [ ] QA visual e de desempenho no Android físico.

## v0.8 — Exploração com significado
- Duas cavernas realmente navegáveis, com entrada/saída e interiores coerentes.
- Novos destroços, suprimentos e enigmas ambientais curtos.
- Marcos rastreados no diário, coleta única e recuperação após save.
- Materiais raros usados em receitas de equipamentos e do barco.
- Melhorar terreno, rochas, árvores, fauna e texturas mantendo a identidade tropical.

## v0.8.0 — Marco entregue no código

- [x] Duas cavernas navegáveis com recursos únicos, minimapa próprio, transições e save interno.
- [x] Quatro selos interativos, dois relicários e recompensas únicas (cristais + recursos).
- [x] Estação de aprimoramento nível 2 pesquisada por descoberta do Leste.
- [x] Ferramentas de metal reforçado, modelos próprios e coleta mais eficiente.
- [x] Ícones de inventário, Diário de pesquisa, receitas com custos reais e persistência.
- [x] Workflow de APK mantém disparo manual somente a pedido.
- [ ] Medir FPS, testar toque/visuais no Android físico.
- [ ] Novos biomas de cavernas profundas, materiais para paredes aprimoradas e enigmas expandidos.

## v0.9 — Barco montado peça a peça
- Etapas: estrutura inicial → casco → piso → mastro → vela → leme.
- Modelos e animações sincronizados com recursos consumidos e etapas registradas.
- Não cobrar materiais duas vezes nem concluir partida antes de terminar todas as partes.
- Experiência de embarque navegável e cena de fuga; preservar compatibilidade com saves com barco antigo.

## v1.0 — Polish e Android
- Ajustar animações/efeitos, músicas, feedback háptico opcional e legibilidade touch.
- Testar em resolução/taxa de quadros reais do Android; reduzir overdraw e draw calls.
- Otimizar occlusion/LOD, shaders, streaming por área e densidade da fauna.
- Fechar todas as histórias, completar QA de progressão inteira, backup e migrations.
- APK assinado com chave original; AAB para publicação apenas após QA, direitos de arte/áudio e preparação da loja.

## Critérios de publicação por versão
Godot parser/import sem erros; testes de gameplay e auditorias aprovadas; nenhuma referência quebrada; pacote sem resíduos temporários; salvar/carregar e fluxo de fuga intactos; APK beta assinado, zipalign de 16 KiB e CRC íntegro. Teste em hardware é requisito para considerar uma versão estável.

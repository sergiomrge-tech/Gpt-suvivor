# Sugestões implementadas — v0.4.0

| Frente | Implementação entregue |
| --- | --- |
| Personagem e ações | Tronco, rosto/cabelo, mãos/dedos, pés/botas, roupa, mochila e articulações de ombros/cotovelos/quadris/joelhos. Poses distintas de corte, mineração, coleta, investigação, pesca, fabricação/construção, cozinha, alimentação, água e descanso. Machadinha, picareta, martelo, vara/linha/boia, alimento e espeto visíveis conforme a ação. |
| Vegetação e caminhos | Sete áreas de geração de árvores de copa em grupos, árvores coletáveis, samambaias, raízes, cobertura vegetal, clareiras e três trilhas calculadas entre praia, nascente e cavernas. Vegetação não é plantada nos centros dos caminhos. |
| Áudio | Treze WAV originais: mar, vento, fogueira, passos em areia/grama/madeira, corte, mineração, martelo, folhagem, água/pesca, alimentação e sinal de interface. Ambiente/efeitos separados; fonte sonora acompanha o contato; listener no personagem; volume do mar varia com a costa; fogueira espacial; pausa e opção de silenciar. |
| Construções | Telhado em camadas, amarrações, contraventamentos e bases de pedra na casa; ferramentas e corda sobre a bancada; rampa e piso transitável no cais. |
| Exploração | Mochila do piloto, diário junto à caverna e caixa de ferramentas. Cada descoberta concede suprimentos uma única vez e acrescenta um registro ao diário persistente. |
| Interface | Barras/textos compactos, minimapa menor, mochila expansível, diário acessível por toque, pesca contextual e progresso/cancelamento de ações. Orientação horizontal configurada. |

A coleta entrega recursos no marcador de contato da animação, após aproximação física ao objeto. Interromper antes do contato não concede recursos. Fabricação e construção continuam registradas atomicamente ao confirmar; o movimento de trabalho é a resposta visual, sem alterar os custos e a progressão existentes. Cancelar essa animação não desfaz uma construção já registrada.

A implementação foi testada no Godot Linux e inspecionada em capturas reais. As poses das capturas de inspeção são preparadas pelo script de QA. A versão ainda é um protótipo com modelos procedurais. Desempenho, conforto do toque e reprodução/mixagem em hardware Android continuam pendentes.

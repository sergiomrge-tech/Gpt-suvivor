# GPT Survivor v2.3 — mapa integrado e Android

Revisão de 14/10/2026, sobre a branch com natureza CC0 e caminhada corrigida.

## Mapa

- Recursos coletáveis usam os modelos novos: coqueiros, árvores, samambaias,
  pedras, troncos caídos e pedras soltas; IDs e progressão são preservados.
- Toda a decoração de solo passa a usar meshes reais do catálogo, com UVs,
  normais, materiais PBR e escala normalizada; remove duplicatas geométricas.
- 121 árvores adicionais distribuídas pelos quatro quadrantes da ilha;
  troncos têm colisão, respeitam trilhas e são removidos na área construída.
- Cavernas com rochas escaneadas, piso PBR e caixas de suprimentos reais;
  entradas, saídas, recompensas e perigos preservados.
- Casa com porta original aberta, bancada, baú, escada e acessórios importados;
  novas chamas substituem a esfera laranja; módulos e cais usam madeira escaneada.
- O casco do barco usa a canoa CC0 a partir da segunda etapa; as cinco fases,
  custos, mastro, vela e fuga continuam operantes.
- Avião menor e asa quebrada mais plana, com peças originais agrupadas por material.
- Materiais agrupados e LODs preparados antes da exportação; a runtime tem
  fallback a partir das fontes originais sem depender de classes do editor.

## Evidência de validação

- Godot 4.6.1: importação/parsing sem erro.
- Gameplay completo: 669/669 verificações, incluindo toque e progressão.
- Integração CC0: 44/44 verificações.
- Mapa v2.3: 1072/1072 verificações de assets, materiais, escalas, colisões e limpeza.
- Caminhada: 2164 verificações, zero falhas.
- Auditorias de arquivos, referências e áudio aprovadas.
- Sete capturas reais revisadas: praia/avião, florestas oeste/norte,
  entrada de caverna, acampamento e interior completo/leve.
- Nas câmeras revisadas, 60–344 chamadas de desenho em renderização por software.
  Esses números não são medições de FPS no Android.
- O pacote exportado também inicia na template de runtime Linux 4.6.1,
  sem erros de script/recurso; isso não equivale a executar no Android.

## APK

Nome: `GPT_Survivor_v2_3_0_Mapa_Atualizado.apk`

- Versão: 2.3.0-world-beta / código 2300.
- Aplicativo: **GPT Survivor Mundo**.
- Package: `com.sergiomrge.gptsurvivor.worldbeta` (separado das betas anteriores).
- Android mínimo 7.0 / API 24; alvo API 35; ARM64.
- Tamanho: 187868780 bytes (179.2 MiB).
- SHA256: `323b7bc33f232852bc4b2f05369c97c6d14d9a79cbb7f7a7a9ea2c8d30f7c044`.
- `apksigner verify --verbose`: aprovado, esquemas v2 e v3.
- `zipalign -c -P 16 4`: aprovado; CRC de todas as entradas aprovado.
- Authorities de Startup e FileProvider distintas; somente manifesto alterado
  entre o export original e a correção, antes de alinhar e assinar.
- Cache otimizado e controlador de caminhada conferidos dentro do APK.
- Instalação e desempenho em aparelho físico ainda não testados nesta sessão.

## Reproduzir o cache de exportação

Depois da importação no Godot 4.6.1:

```bash
godot --headless --path . --script res://tools/bake_world_assets.gd
godot --headless --path . --export-debug Android ../export/GPT_Survivor_v23_unsigned.apk
```

O cache `assets/optimized_world/` é gerado a partir das fontes versionadas e
incluído no APK; não precisa ser mantido como uma segunda cópia no Git.
A chave de teste foi preservada privadamente para as próximas revisões;
não se encontra no repositório. Reutilizá-la ao gerar futuras atualizações
com este package. Alinhar antes de assinar, verificar assinatura/alinhamento/CRC
antes de entregar. As betas anteriores continuam independentes.

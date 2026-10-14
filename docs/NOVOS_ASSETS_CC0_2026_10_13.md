# GPT Survivor — novos modelos realistas CC0 (pesquisa de 13/10/2026)

Este branch de **aquisição**, separado do jogo, baixa modelos reais em glTF e texturas 1k (se disponíveis). A integridade SHA256 de cada dependência é verificada e o ZIP é testado antes de publicar. Os pacotes são arquivos de origem, **não importações Godot automaticamente aprovadas**.

Árvores e troncos: Island Tree 01, Island Tree 03, Tree Stump 01, Dead Tree Trunk 02.
Rochas: Boulder 01, Rock 07, Rock Face 01.
Estruturas: Wooden Ladder 02.

Fonte/licença: https://polyhaven.com/license (CC0, inclusive uso comercial). Proveniência e URLs de arquivos registrados em `asset_downloads/2026-10-13/CATALOGO_CC0.json`. Alguns modelos de árvores têm milhões de triângulos, portanto **não devem ser usados diretamente em Android** sem LOD/redução de malha e aferição de FPS. Script recusa modelos maiores que 80 MB e registra falhas no catálogo, em vez de afirmar falsamente que foram baixados.

## Execução

GitHub Actions: workflow `Acquire CC0 realistic trees rocks and structures`. A execução é acionada ao publicar/alterar este downloader na branch. Artefato gerado: `Survivor-CC0-Nature-Assets-Models-And-Catalog`.

Sem alterar a versão jogável, sem APK, sem sobrescrever modelos já aprovados.

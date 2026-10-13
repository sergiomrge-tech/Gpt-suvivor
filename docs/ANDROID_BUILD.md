# APK Android v0.4.0

APK de teste exportado em Godot 4.6.1, assinado com chave privada própria e preservada fora do GitHub. Package `com.sergiomrge.gptsurvivor`, versão 0.4.0, versionCode 400, arm64-v8a, Android 7.0+ (SDK 24), target 35, OpenGL Compatibility, paisagem.

## Reprodução

Instalar os templates oficiais 4.6.1, Java 17, Android SDK platform-tools e Build Tools 35.0.1; configurar esses caminhos no editor Godot. Definir GODOT_BIN, ANDROID_SDK_ROOT, SURVIVOR_KEYSTORE e SURVIVOR_PASSWORD_FILE; executar `tools/android/build_android.sh /pasta/fora/do/projeto`. Não colocar chave ou senha no repositório. O preset exporta um APK sem assinatura; o script corrige o manifesto, alinha em 16 KB, assina e verifica.

Godot 4.6.1 altera todos os atributos de authorities para `.fileprovider`, incluindo AndroidX Startup. `fix_android_manifest.py` restaura `.androidx-startup` somente para InitializationProvider, conserva FileProvider e verifica que apenas AndroidManifest.xml mudou antes da assinatura. O parser rejeita formatos inesperados.

## Evidência desta entrega

- 101/101 testes nativos, auditoria de fontes/referências e 13 arquivos de áudio aprovados.
- Exportação release concluída; payload compilado extraído do APK executado headless por 180 frames sem erros.
- apksigner verify: assinaturas v2 e v3 válidas, sem elevar artificialmente o SDK mínimo.
- zipalign -c -P 16 4 aprovado; segmentos ELF PT_LOAD das duas bibliotecas têm alinhamento de ao menos 16 KB.
- CRC do ZIP aprovado, cena principal/scripts compilados e os 13 sons presentes; testes/documentação fora do APK.
- Manifesto com launcher, ícone adaptativo, paisagem e authorities distintas; nenhuma permissão solicitada.
- Instalação, áudio, toque e desempenho no Android ainda não testados: não há aparelho conectado neste ambiente.

APK: 26251869 bytes; SHA-256 `012194587d6214bdae42bbbb4c7acf64fd7df0db65dab6f1f1ef99e20b776a0a`.

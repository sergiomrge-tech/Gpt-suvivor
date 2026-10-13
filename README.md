# GPT Survivor — Ilha Perdida

Protótipo 3D de sobrevivência feito **inteiramente em Godot 4.x / GDScript**.
A base principal do projeto fica neste repositório. O mundo é criado em runtime, sem texturas ou modelos externos.

## Jogar no editor

1. Abra o projeto `project.godot` com **Godot 4.4.1+**.
2. Pressione **F5** e clique em **NOVA SOBREVIVÊNCIA**.
3. Use **WASD/setas** ou joystick touch para explorar a ilha.

| Comando | Ação |
| --- | --- |
| WASD / setas / joystick | Mover o sobrevivente |
| E / COLETAR | Coletar recurso próximo |
| F / PESCAR | Pescar na praia (requer lança) |
| H / COMER | Comer frutas ou peixe |
| T / BEBER | Beber água coletada |
| B / CRIAR | Abrir fabricação |
| P / SALVAR | Salvar progresso local |
| Esc / MENU | Menu principal (salva automaticamente) |

## Loop de sobrevivência

Explore uma ilha de aproximadamente 400m de diâmetro. Recolha árvores, coqueiros, rochas, madeira à deriva, frutas e água doce. Fabrique uma **lança** para pescar e construa **fogueira**, **abrigo**, **coletor de água**, **bancada** e finalmente uma **jangada**, que encerra a sessão com vitória.

Fome e sede diminuem com o tempo e, se zerarem, a saúde também se perde. O coletor gera água automaticamente a cada 90 segundos. Há ciclo de luz diurno e salvamento versionado no armazenamento do dispositivo (`user://survivor_save_v1.json`).

## Arquitetura

- `scripts/game.gd`: coordenação de cena, input e interações.
- `scripts/terrain.gd`: malha procedural da ilha, oceano, iluminação e horários.
- `scripts/world.gd`: objetos coletáveis, vegetação e construções procedurais.
- `scripts/player.gd`: personagem 3D e movimento.
- `scripts/survival_state.gd`: vitais, inventário, receitas e persistência.
- `scripts/hud.gd`: interface, menu, crafting e ações touch.
- `scripts/joystick.gd`: joystick virtual multitouch.
- `.github/workflows/godot-check.yml`: validação automatizada de import, testes de estado e boot headless.

## Estado de desenvolvimento

**v0.2 — vertical slice, em validação.** O código da primeira partida está integrado, porém ainda faltam testes gráficos e de toque num celular real, assets autorais polidos, animações completas e compilação de APK/AAB. Nenhuma renderização ilustrativa deve ser confundida com uma captura real do jogo.

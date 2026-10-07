# 🌫️ PUYU (プユ)
> **Survival Horror Andino en Tercera Persona con Estética Retro de PlayStation 2**  
> Desarrollado en **Godot Engine 4.7** con motor de físicas **Jolt Physics**.

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.7.2-478cbf?logo=godotengine&logoColor=white)
![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20Windows%20%7C%20Linux-brightgreen)
![Estilo](https://img.shields.io/badge/Estética-PS2%20Retro%20Horror-crimson)
![Físicas](https://img.shields.io/badge/Physics-Jolt%203D-orange)

---

## 🏔️ Sinopsis & Lore

**PUYU** (*"Niebla"* en quechua) transporta al jugador a un pueblo abandonado en las alturas de los Andes peruanos, devorado por una bruma densa y perpetua. 

En medio del silencio sepulcral resuena una risa metálica y estridente: **La Jarjacha**. En el mito andino, la Jarjacha es la manifestación de un condenado, un ser humano transformado en una bestia monstruosa de cuello desmesurado, pezuñas pesadas y mandíbula dislocada que acecha durante las noches de niebla.

Para sobrevivir, el jugador no es un cazador sobrehumano: es un superviviente que debe usar su entorno, la arquitectura de adobe y piedra, la soga de cabuya y las pocas armas que encuentre para someter y liquidar a la criatura antes de que la niebla lo consuma.

---

## 🎮 Mecánicas Principales

### 🪢 1. Mecánica de Contención: Soga y Amarre a Postes (Multi-Tether)
La Jarjacha es demasiado fuerte y veloz para enfrentarla a campo abierto. El jugador puede engrilletarla y limitar su movimiento:
* **Lanzamiento de Lazo**: Permite atrapar a la criatura por el cuello. La probabilidad de éxito aumenta atacando desde tejados o en sigilo por la espalda.
* **Amarre a Postes de Piedra**: Una vez enlazada, el jugador puede correr a los postes del pueblo y anclar la soga (`[E]`).
* **Multi-Amarre Progresivo**:
  * **1 Poste**: La bestia queda contenida en un radio de 5 metros, pero forcejea con furia.
  * **2 Postes**: La tensión cruzada reduce drásticamente su velocidad y restringe sus ataques.
  * **3 Postes**: Contención triangular total. La criatura queda inmovilizada en el suelo, abriendo la ventana perfecta para ataques críticos.
* **Forcejeo y Rotura de Soga**: La bestia tira con violencia de las cuerdas. Si no se le castiga o se le amarra a más postes, romperá los amarres:
  * **1 Poste**: Resiste **7.5 segundos** antes de romperse. Al zafarse, entra en persecución furiosa con velocidad aumentada.
  * **2 Postes**: Resiste **20.0 segundos** antes de que ceda una soga.
  * **3 Postes**: Resiste **42.0 segundos** de inmovilización absoluta.
* **Feedback de Tensión**: Las cuerdas pierden comba, vibran físicamente a alta frecuencia y pulsan en rojo vivo antes de crujir y romperse (`¡CRAC!`).

---

### 🪓 2. Combate Táctico, Headshots y Combos QTE
* **Hitbox de Cabeza y Daño Crítico (2.5x)**: La Jarjacha cuenta con una hitbox dedicada en el cráneo (`HeadArea`). Tanto los disparos de escopeta como los hachazos directos a la mandíbula infligen daño devastador, aturdimiento y sacudida de retroceso.
* **Empujón de Rechazo / Combo Flotante**:
  * Cuando la bestia se abalanza en carrera corta ($\le 3.8\text{ m}$), aparece una alerta dinámica sobre su cabeza.
  * Al presionar `[F]` (o tocar el botón flotante en Android), el jugador asesta un empujón contundente (16.0 fuerza con hacha), arrojando a la criatura hacia atrás y aturdiéndola durante **2.5 segundos**.
  * **El aturdimiento rescata tiempo**: Cada empujón o tiro crítico a la cabeza le descuenta tiempo de forcejeo a la soga, evitando que se escape.
* **Arsenal Disponible**:
  * **Soga de Cabuya**: Herramienta de caza y restricción física.
  * **Hacha de Tala**: Arma pesada con bonificación de daño contra enemigos amarrados (+60%).
  * **Machete Rústico**: Ataques rápidos de bajo consumo.
  * **Escopeta de Perdigones**: 7 proyectiles con dispersión y recarga táctica cartucho a cartucho.

---

### 👁️ 3. Sigilo y Movimiento Andino
* **Pegado a Muros (`Wall Hug`)**: El jugador puede pegarse a paredes de adobe y pircas de piedra (`[Q]`) para esconderse de la vista de la Jarjacha y asomarse por las esquinas (`[F]`).
* **Sensores de la IA**: La criatura posee cono de visión de $110^\circ$ y escucha pasos acelerados (sprint), alertándose e investigando ruidos en la niebla.

---

## 📱 Controles (PC y Android)

El juego cuenta con soporte simultáneo para teclado/ratón en PC y controles táctiles nativos en Android con pantalla completa (`aspect="expand"`):

| Acción | Teclado & Ratón (PC) | Táctil (Android) |
|---|---|---|
| **Moverse** | `W`, `A`, `S`, `D` | **Joystick Virtual 360°** (Esquina inf. izquierda) |
| **Mirar / Cámara** | Ratón | **Swipe Look** (Mitad derecha de pantalla) |
| **Atacar / Disparar** | Clic Izquierdo | Botón **ATACAR** |
| **Apuntar (Hombro)** | Clic Derecho | Botón **APUNTAR** |
| **Combo ¡EMPUJAR!** | Tecla `F` o Clic al botón flotante | **Tocar botón flotante sobre la criatura** |
| **Saltar** | Barra Espaciadora | Botón **SALTO** |
| **Interactuar / Anclar** | Tecla `E` | Botón **USAR** |
| **Recargar Escopeta** | Tecla `R` | Botón **CARGAR** (Visible al vaciarse) |
| **Cambiar de Arma** | Teclas `1`, `2`, `3`, `4` | **Dock de Armas** o botón **↻ ARMA** |
| **Pegarse al Muro** | Mantener `Q` | — |

---

## 🎨 Dirección de Arte: PS2 Retro Horror

* **Resolución Nativa**: Renderizado a $640 \times 360$ píxeles, escalado con filtrado Nearest para preservar el pixel-art 3D de la era PS2/Dreamcast.
* **Vertex Jitter Shader** (`ps2_lit.gdshader`): Simula la imprecisión de punto flotante y el temblor poligonal característico de consolas de quinta y sexta generación.
* **Arquitectura Autóctona**: Modelos modulares de casas de adobe, pircas de piedra rústica, techos de teja colonial y calamina oxidada, con apachetas y postes de madera andina.

---

## 🗺️ Roadmap de Desarrollo (GDD)

### ✅ Implementado (Fase Actual)
- [x] Controlador del jugador en tercera persona con cámara de hombro y salto amortiguado.
- [x] Shaders de iluminación vertex y post-procesado retro PS2.
- [x] IA de la Jarjacha: Estados de Patrulla, Investigación, Caza, Ataque, Aturdimiento y Fases.
- [x] Sistema de lazo y amarre físico a postes múltiples con cálculo de tensión elástica.
- [x] Mecánica de forcejeo activo y rotura progresiva de sogas (7.5s, 20s, 42s) con feedback visual.
- [x] Hitbox de cabeza con daño crítico (2.5x) y animaciones de retroceso cefálico.
- [x] Mecánica de empujón y combo QTE proyectado en 3D sobre el enemigo.
- [x] Interfaz y controles táctiles nativos para Android (Joystick, dock de armas, swipe camera).
- [x] Arquitectura modular de casas andinas con texturas artesanales.

### 🔨 En Desarrollo / Próximos Pasos
- [ ] **Nuevas Criaturas del Bestiario Andino**:
  - *El Muki*: Duende minero veloz que apaga fuentes de luz y roba herramientas.
  - *El Pishtaco / Kharisiri*: Cazador de grasa humana con cuchillo curvo y campana hipnótica.
- [ ] **Sistema de Alquimia y Crafteo Rústico**:
  - Infusiones de ruda y muña para calmar el pulso del personaje.
  - Teas de grasa y brea para repeler bestias en callejones oscuros.
- [ ] **Mecánicas de Sonido Dinámico**:
  - Sonido de quenas desoladas, cencerros lejanos y risa estertórea de la Jarjacha modulada según la distancia y la niebla.
- [ ] **Puzzles de Entorno**:
  - Templos con campanas de bronce que aturden a la Jarjacha a gran escala al tocarlas en sincronía.
- [ ] **Export Final y Optimización**:
  - Generación de APK firmado para Android listo para Google Play / Sideload.
  - Compilaciones ejecutables nativas para Windows x64 y Linux.

---

## 🛠️ Estructura del Proyecto

```text
puyu/
├── assets/                  # Texturas de adobe, tejas, madera y audio
├── scenes/
│   ├── architecture/       # Casas modulares, fachadas, techos, pircas
│   ├── enemies/            # Escena de la Jarjacha, barras de vida 3D
│   ├── props/              # Postes de amarre, pickups de armas, soga visual
│   ├── ui/                 # Joystick virtual y controles táctiles móviles
│   ├── player.tscn         # Jugador, cámara, linterna y CanvasLayer HUD
│   └── plaza_principal.tscn# Escenario principal de la plaza andina
├── scripts/
│   ├── jarjacha.gd         # IA, estados, forcejeo y daño de la criatura
│   ├── player.gd           # Movimiento, combate, lazo, headshots y combos
│   ├── rope_visual.gd      # Renderizado de cuerdas con curvatura y estrés
│   └── ui/                 # Controladores táctiles y joystick móvil
├── shaders/
│   ├── ps2_lit.gdshader    # Shader vertex jitter y retro lighting
│   └── ps2_postprocess.gdshader # Post-procesado de niebla y dithering
└── project.godot           # Configuración del motor y mapeo de inputs
```

---

## 🚀 Instalación y Ejecución

1. Clona el repositorio:
   ```bash
   git clone https://github.com/christoper-d/puyu.git
   ```
2. Abre **Godot Engine 4.7+**.
3. Importa el archivo `project.godot`.
4. Presiona **F5** para ejecutar la escena principal (`scenes/plaza_principal.tscn`).

---

## 🤝 Contribución y Flujo de Ramas

Para colaborar en el desarrollo de **PUYU**, revisa nuestra [Guía de Contribución](CONTRIBUTING.md) con la convención de ramas (`feature/V101-...`, `hotfix/V101-...`), estándares de commits y proceso de Pull Requests.

---

*Desarrollado por **dj** (@christoper-d)*


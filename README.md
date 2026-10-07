# 🌫️ PUYU (プユ)
> **Survival Horror Andino en Tercera Persona con Estética Retro de PlayStation 2**  
> Desarrollado en **Godot Engine 4.7** con motor de físicas **Jolt Physics**.

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.7.2-478cbf?logo=godotengine&logoColor=white)
![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20Windows%20%7C%20Linux-brightgreen)
![Estilo](https://img.shields.io/badge/Estética-PS2%20Retro%20Horror-crimson)
![Físicas](https://img.shields.io/badge/Physics-Jolt%203D-orange)

---

## 📌 ¿Qué es PUYU?

* **Concepto:** Survival horror en tercera persona ambientado en un pueblo abandonado en las alturas de los Andes peruanos.
* **Atmósfera:** Una densa niebla perpetua (*Puyu*) que devora las calles empedradas, arquitectura de adobe y tejados de calamina.
* **La Amenaza:** **La Jarjacha**, un ser condenado mitad humano y mitad bestia zoomórfica con risa macabra, cuello desmesurado y mandíbula dislocada que acecha en la bruma.
* **Propuesta Única:** El jugador no es un cazador sobrehumano. Sobrevive utilizando sigilo, armas rústicas y una mecánica física de **contención con sogas y postes** para someter a la criatura antes de eliminarla.

---

## 📚 Documentación del Proyecto

El desarrollo y diseño técnico de PUYU se organiza de manera modular en documentos dedicados:

| Documento | Descripción |
|---|---|
| 📐 [**Arquitectura de Software**](ARCHITECTURE.md) | Component Pattern, EventBus, FSM modular de IA y Resources para escalar el código. |
| 🤝 [**Guía de Contribución y Ramas**](CONTRIBUTING.md) | Reglas de ramas directas de `main`, prefijos (`feature/V101-...`) y Pull Requests. |
| 📝 [**Concepto Original**](puyu_concept.md) | Documento fundacional con las primeras notas de diseño y estética. |

---

## 🎮 Mecánicas Clave (Puntual)

### 🪢 1. Contención Multi-Tether (Soga & Postes)
* **Lanzamiento de Lazo:** Atrapa a la criatura por el cuello desde tejados o sigilo.
* **Anclaje a Postes:** Corre a postes de piedra para asegurar las cuerdas (`[E]`).
* **Forcejeo y Rotura Progresiva:**
  * **1 Poste:** Resiste **7.5 segundos** $\rightarrow$ La soga se rompe y la Jarjacha entra en persecución furiosa.
  * **2 Postes:** Resiste **20.0 segundos** $\rightarrow$ Cede una soga y la criatura queda atada a 1 poste.
  * **3 Postes:** Resiste **42.0 segundos** $\rightarrow$ Inmovilización triangular total.
* **Tensión Visual:** Las cuerdas pierden curvatura, vibran con micro-sacudidas físicas y pulsan en rojo antes de crujir.

### 🪓 2. Combate Táctico, Críticos y Combos
* **Hitbox de Cabeza (2.5x):** Disparos de escopeta y hachazos a la mandíbula causan daño masivo, aturdimiento y retroceso.
* **Empujón de Rechazo / Combo QTE:** Al acercarse la bestia ($\le 3.8\text{ m}$), presionar `[F]` (o tocar el botón flotante en Android) la arroja hacia atrás, aturdiéndola 2.5s y retrasando el forcejeo de las cuerdas.
* **Arsenal:** Soga de cabuya, hacha de tala (+60% daño amarrada), machete y escopeta de perdigones con recarga táctica.

### 👁️ 3. Sigilo Andino (Wall Hug)
* Pegarse a muros de adobe y pircas con `[Q]` para eludir la visión de $110^\circ$ y el oído de la criatura.

---

## 📱 Controles (PC & Android)

| Acción | PC (Teclado + Ratón) | Android (Táctil) |
|---|---|---|
| **Moverse** | `W`, `A`, `S`, `D` | **Joystick Virtual 360°** (Inf. Izquierda) |
| **Girar Cámara** | Movimiento del Ratón | **Swipe Look** (Mitad Derecha) |
| **Atacar / Disparar** | Clic Izquierdo | Botón **ATACAR** |
| **Apuntar** | Clic Derecho | Botón **APUNTAR** |
| **Empujar / Combo** | Tecla `F` o Clic en botón | **Tocar botón flotante sobre la criatura** |
| **Saltar** | Barra Espaciadora | Botón **SALTO** |
| **Interactuar / Anclar** | Tecla `E` | Botón **USAR** |
| **Recargar** | Tecla `R` | Botón **CARGAR** (Dinámico) |
| **Cambiar Arma** | Teclas `1`, `2`, `3`, `4` | **Dock de Armas** o botón **↻ ARMA** |

---

## 🎨 Dirección de Arte: PS2 Retro

* Render nativo a $640 \times 360$ con escalado expandido.
* Shader vertex jitter (`ps2_lit.gdshader`) sin filtrado bilineal (Nearest).
* Motor de físicas Jolt 3D.

---

## 🗺️ Roadmap Modular de Desarrollo

Iremos desbloqueando y completando sección tras sección:

- [x] **Sección 1: Movimiento, Cámara y Shaders PS2** *(Completado)*
- [x] **Sección 2: IA Básica de la Jarjacha y Fases** *(Completado)*
- [x] **Sección 3: Contención Física con Sogas y Tensión** *(Completado)*
- [x] **Sección 4: Hitbox de Cabeza, Críticos y Combo de Empujón** *(Completado)*
- [x] **Sección 5: Controles Táctiles Nativos para Android** *(Completado)*
- [ ] **Sección 6: Refactorización a EventBus y WeaponData** *(Siguiente paso)*
- [ ] **Sección 7: Integración del Modelo 3D del Personaje Principal** *(En cola)*
- [ ] **Sección 8: Nueva Criatura: El Muki de las Minas** *(Planificado)*
- [ ] **Sección 9: Sistema de Alquimia y Crafteo Rústico** *(Planificado)*
- [ ] **Sección 10: Compilación Final y APK para Android** *(Planificado)*

---

## 🚀 Inicio Rápido

1. Clona el repositorio:
   ```bash
   git clone https://github.com/christoper-d/puyu.git
   ```
2. Abre **Godot Engine 4.7+**, importa `project.godot` y presiona **F5** para ejecutar `scenes/plaza_principal.tscn`.

---

*Desarrollado por **dj** (@christoper-d)*

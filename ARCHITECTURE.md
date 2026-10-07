# 📐 Arquitectura de Software — PUYU

Este documento define los principios arquitectónicos, patrones de diseño y estándares técnicos de **PUYU** para garantizar que el proyecto sea modular, escalable y mantenible a medida que se agregan nuevos enemigos, armas y mecánicas.

---

## 🏛️ 1. Filosofía de Diseño en Godot 4

En el desarrollo de software tradicional es común recurrir a jerarquías profundas de herencia de clases. En Godot Engine y el desarrollo de videojuegos moderno, la regla de oro es:

> **"Composición sobre Herencia"** y **"Desacoplamiento mediante Señales"**

```
┌─────────────────────────────────────────────────────────────┐
│                    EVENT BUS (Events.gd)                    │
│      Bus global de señales (UI, Combate, Tensión, Audio)    │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
    ┌──────────────────────┐      ┌──────────────────────┐
    │     PLAYER NODE      │      │     ENEMY NODE       │
    │  (Component Pattern) │      │  (State Machine FSM) │
    ├──────────────────────┤      ├──────────────────────┤
    │ • PlayerMovement     │      │ • State_Patrol       │
    │ • PlayerCombat       │      │ • State_Chase        │
    │ • PlayerLasso        │      │ • State_Tethered     │
    │ • PlayerInventory    │      │ • State_Stunned      │
    │ • WallHug            │      │ • State_Attack       │
    └──────────┬───────────┘      └──────────┬───────────┘
               │                             │
               ▼                             ▼
    ┌──────────────────────┐      ┌──────────────────────┐
    │  RESOURCES (Datos)   │      │  RESOURCES (Stats)   │
    │  • escopeta.tres     │      │  • jarjacha.tres     │
    │  • hacha.tres        │      │  • muki.tres         │
    └──────────────────────┘      └──────────────────────┘
```

---

## 🔍 2. Diagnóstico del Estado Actual (Auditoría Técnica)

Actualmente el juego cuenta con un prototipo jugable validado, pero presenta los siguientes síntomas de acoplamiento que deben refactorizarse:

| Síntoma | Ubicación Actual | Riesgo / Limitación | Solución Arquitectónica |
|---|---|---|---|
| **God Object (Monolito)** | `scripts/player.gd` (~840 líneas) | Maneja físicas, cámara, inventario, soga, escopeta, HUD y controles móviles en un solo script. Cualquier cambio puede romper otra mecánica. | **Pilar 1: Composición de Nodos** |
| **FSM Monolítica** | `scripts/jarjacha.gd` (~620 líneas) | Máquina de estados controlada por un `match current_state` gigante. Dificulta crear nuevos enemigos como El Muki sin duplicar código. | **Pilar 2: FSM Modular** |
| **Acoplamiento Directo** | Player $\leftrightarrow$ Jarjacha $\leftrightarrow$ HUD | El enemigo busca al jugador directamente para pedir textos en el HUD (`player_ref._flash_prompt`), y el jugador busca enemigos con `get_nodes_in_group`. | **Pilar 3: EventBus Global** |
| **Datos Quemados (Hardcoded)** | Variables de daño en código | Daño, rango y multiplicadores están escritos en el código fuente (`damage = 35.0`, `65.0`). | **Pilar 4: Custom Resources** |

---

## 🧱 3. Los 4 Pilares Arquitectónicos

### Pilar 1: Composición por Nodos (Component Pattern)
En lugar de que `Player` concentre toda la lógica, el nodo raíz `Player (CharacterBody3D)` delega responsabilidades a nodos hijos especializados:

* **`PlayerMovement` (Node):** Velocidades de marcha, sprint, salto amortiguado, coyote time y vector del joystick móvil.
* **`PlayerCombat` (Node):** Manejo de disparos de escopeta, perdigones, hachazo, detección de headshots y combos.
* **`PlayerLasso` (Node):** Lanzamiento de soga, tensión con la criatura y anclaje a postes.
* **`PlayerInventory` (Node):** Registro de armas recolectadas, munición y selección activa.
* **`WallHug` (Node):** *(Ya implementado)* Detección de muros de adobe y asomarse por esquinas.

---

### Pilar 2: Máquina de Estados Finita Modular (FSM)
Cada estado de la IA es una clase aislada con un ciclo de vida definido:

```gdscript
class_name State
extends Node

func enter(_host: CharacterBody3D) -> void: pass
func exit(_host: CharacterBody3D) -> void: pass
func physics_update(_host: CharacterBody3D, _delta: float) -> void: pass
```

* **Controlador `StateMachine` (Node):** Administra el estado activo y las transiciones válidas.
* **Estados de la Jarjacha:**
  * `StatePatrol.gd`: Recorrido entre waypoints del pueblo.
  * `StateInvestigate.gd`: Búsqueda de ruidos de pisadas.
  * `StateChase.gd`: Persecución directa con boost por furia.
  * `StateTethered.gd`: Cálculo de tensión de sogas, forcejeo y rotura progresiva (7.5s, 20s, 42s).
  * `StateStunned.gd`: Aturdimiento por empujón o impacto crítico.
* **Reutilización:** Cuando se desarrolle **El Muki** o **El Pishtaco**, reutilizarán el mismo controlador `StateMachine` y estados base, cambiando únicamente parámetros y animaciones.

---

### Pilar 3: EventBus Global (`Events.gd`)
Un `Autoload` global que actúa como intermediario de mensajería para desacoplar sistemas:

```gdscript
# res://scripts/core/events.gd
extends Node

# Señales de HUD e Interfaz
signal prompt_flashed(mensaje: String, duracion: float)
signal combo_prompt_visibility_changed(target_enemy: Node3D, visible: bool)

# Señales de Combate y Salud
signal enemy_damaged(enemy: Node, damage: float, is_headshot: bool)
signal enemy_tether_changed(enemy: Node, tether_count: int, stress_ratio: float)
signal player_health_changed(current: float, max_val: float)
signal weapon_switched(weapon_type: int)
```

**Ventaja:** Si la Jarjacha entra en estrés y va a romper una soga, emite:
```gdscript
Events.prompt_flashed.emit("¡¡CRAC!! ¡La soga está a punto de romperse!", 2.2)
```
La UI reacciona sin que la Jarjacha tenga ninguna referencia directa al Player ni a la escena del HUD.

---

### Pilar 4: Diseño Basado en Datos (Custom Resources)
Los datos de combate y configuración se extraen a archivos de recurso de Godot (`.tres`):

```gdscript
class_name WeaponData
extends Resource

@export var id: String = "shotgun"
@export var display_name: String = "Escopeta de Caza"
@export var base_damage: float = 65.0
@export var headshot_multiplier: float = 2.5
@export var range_distance: float = 25.0
@export var is_blunt: bool = true
@export var icon: Texture2D
```

* Los archivos se guardan en `resources/weapons/`:
  * `hacha.tres`
  * `escopeta.tres`
  * `machete.tres`
* Permite balancear daño, cadencia y alcance desde el Inspector de Godot sin tocar código ejecutable.

---

## 📂 4. Estructura de Directorios Objetivo

```text
puyu/
├── assets/
│   ├── models/            # Mallas 3D (.glb, .gltf)
│   ├── textures/          # Texturas pixel-art / albedo
│   └── audio/             # Efectos de sonido y ambiente
├── resources/
│   ├── weapons/           # Archivos .tres de armas
│   └── enemies/           # Archivos .tres de stats de enemigos
├── scenes/
│   ├── architecture/      # Casas modulares, fachadas, techos
│   ├── enemies/           # Escenas de criaturas (Jarjacha, Muki)
│   ├── props/             # Postes, pickups, sogas
│   ├── ui/                # HUD, joystick móvil, combo button
│   └── levels/            # Escenas de niveles (plaza_principal, etc.)
├── scripts/
│   ├── core/              # Autoloads (events.gd, game_manager.gd)
│   ├── player/            # Controlador y componentes del jugador
│   │   ├── components/    # movement, combat, lasso, inventory
│   │   └── player.gd      # Nodo coordinador central
│   ├── enemies/           # IA y FSM de enemigos
│   │   ├── fsm/           # state_machine.gd, state.gd
│   │   └── jarjacha/      # estados específicos de la Jarjacha
│   └── ui/                # Controladores de interfaz y móvil
└── shaders/               # ps2_lit.gdshader, ps2_postprocess.gdshader
```

---

## 🗺️ 5. Plan de Migración Progresiva

Para no frenar el desarrollo creativo, la refactorización se realiza por etapas incrementales:

1. **Fase 1: Implementación del EventBus**  
   Crear `scripts/core/events.gd` y conectar alertas del HUD y daños a través de señales globales.
2. **Fase 2: Migración a WeaponData (Resources)**  
   Reemplazar el enum numérico de armas por recursos `.tres` para daño, rango y multiplicadores.
3. **Fase 3: Desacoplamiento de la FSM de Enemigos**  
   Extraer los estados de `jarjacha.gd` a clases modulares reutilizables para el siguiente enemigo (*El Muki*).
4. **Fase 4: Modularización del Player en Componentes**  
   Separar combate, lazo y movimiento en nodos hijos.

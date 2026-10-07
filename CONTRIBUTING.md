# 🤝 Guía de Contribución y Flujo de Trabajo — PUYU

Bienvenido a la guía de desarrollo de **PUYU**. Para mantener el proyecto estable, colaborativo y con un historial limpio en GitHub, todo el equipo debe seguir este flujo de trabajo estandarizado con ramas y prefijos.

---

## 🌳 1. Regla de Oro: Ramas Directas desde `main`

1. **La rama `main` es sagrada**: Siempre debe estar en un estado funcional, jugable y compilable sin errores.
2. **Nunca se hace commit directo a `main`**: Toda nueva característica, corrección o asset se desarrolla en su propia rama aislada.
3. **Toda rama nace directamente de `main`**:
   Antes de empezar cualquier tarea, asegúrate de tener la última versión de `main`:
   ```powershell
   git checkout main
   git pull origin main
   ```

---

## 🏷️ 2. Convención de Nomenclatura de Ramas

Los nombres de las ramas deben seguir la estructura obligatoria:

```text
<tipo>/<código-versión>-<Accion>-<descripción-breve>
```

### Prefijos Oficiales:

| Prefijo | Uso | Ejemplo |
|---|---|---|
| `feature/` | Nuevas mecánicas, enemigos, armas, niveles o interfaces. | `feature/V101-Implementacion-ia-muki` |
| `hotfix/` | Corrección urgente de bugs críticos, crashes o bloqueos en producción. | `hotfix/V101-correccion-cuerda-estiramiento-infinito` |
| `bugfix/` | Corrección de errores menores, físicas, ajustes de hitbox o cámara. | `bugfix/V101-arreglo-hitbox-cabeza-jarjacha` |
| `refactor/` | Limpieza, optimización de código o shaders sin alterar jugabilidad. | `refactor/V101-optimizacion-ps2-shader` |
| `assets/` | Inclusión o actualización de modelos 3D, texturas, sonidos o música. | `assets/V101-agregado-texturas-adobe-nuevas` |
| `docs/` | Cambios exclusivos en documentación (`README.md`, guías, etc.). | `docs/V101-actualizacion-gdd` |

### Estructura de Nombres:
* Usa siempre el código de versión/iteración (ej. `V101`, `V102`, etc.).
* Usa verbos en acción: `Implementacion`, `correccion`, `arreglo`, `optimizacion`.
* Usa palabras separadas por guiones (`kebab-case`), todo en minúsculas después del prefijo.

---

## 🚀 3. Ciclo de Trabajo Paso a Paso

### Paso 1: Actualizar `main` y crear tu rama
```powershell
# 1. Asegurar que estás en main actualizado
git checkout main
git pull origin main

# 2. Crear y moverte a la nueva rama
git checkout -b feature/V101-Implementacion-combo-patada
```

### Paso 2: Desarrollar y verificar en Godot
1. Trabaja en tus escenas, scripts o shaders en Godot 4.
2. Abre la consola de depuración de Godot y confirma que **no hay errores en rojo** ni warnings innecesarios.
3. Prueba la mecánica tanto con mouse/teclado como con el modo táctil si aplica a UI.

### Paso 3: Commits Atómicos y Convencionales
Haz commits pequeños y descriptivos siguiendo la convención de [Conventional Commits](https://www.conventionalcommits.org/):

* `feat:` Nueva funcionalidad (`feat: agregar combo de empujón al presionar F`)
* `fix:` Corrección de error (`fix: corregir detección de headshot en colisiones anidadas`)
* `perf:` Mejora de rendimiento (`perf: optimizar cálculo de jitter en shader PS2`)
* `refactor:` Refactorización de código sin cambio funcional
* `docs:` Cambios en documentación
* `style:` Formato o indentación sin cambios de lógica

```powershell
git add .
git commit -m "feat: implementar boton de combo flotante sobre la jarjacha"
```

### Paso 4: Subir la rama a GitHub
La primera vez que subas tu rama, usa la bandera `-u`:
```powershell
git push -u origin feature/V101-Implementacion-combo-patada
```

### Paso 5: Abrir un Pull Request (PR)
1. Entra a [github.com/christoper-d/puyu](https://github.com/christoper-d/puyu).
2. Verás el botón amarillo **Compare & pull request** para tu rama.
3. Asegúrate de que el objetivo sea `base: main` $\leftarrow$ `compare: tu-rama`.
4. En la descripción incluye:
   * **¿Qué hace este cambio?** (Resumen de la mecánica o corrección).
   * **¿Cómo probarlo?** (Escena donde probar y teclas a presionar).
   * **Capturas o video** (si es visual o de interfaz).
5. Solicita revisión y realiza el merge una vez aprobado.

### Paso 6: Limpieza local tras el Merge
Una vez que el PR fue aceptado e integrado en `main`:
```powershell
git checkout main
git pull origin main
git branch -d feature/V101-Implementacion-combo-patada
```

---

## 🛡️ 4. Reglas Técnicas y Estándares de PUYU

1. **Estética Retro PS2 Intacta**:
   - Todo modelo 3D debe usar el shader [`ps2_lit.gdshader`](file:///C:/Users/g4briel/Documents/puyu/shaders/ps2_lit.gdshader) con filtrado `Nearest` en texturas.
   - Mantener resolución nativa a $640 \times 360$ con `stretch/mode="viewport"`.
2. **Calidad de GDScript**:
   - Usa tipado estático siempre que sea posible (`delta: float`, `amount: float`, `is_headshot: bool = false`).
   - Usa `_` para variables o argumentos privados/no utilizados (`_delta`).
3. **Respeto a `.gitignore`**:
   - Nunca fuerces (`git add -f`) la carpeta `.godot/`, la carpeta `builds/` ni archivos `.apk` / `.tmp`.
4. **Físicas y Capas de Colisión**:
   - Capa 1: Escenario / Mundo.
   - Capa 2: Jugador.
   - Capa 3 (valor 4): Enemigos y áreas de hitbox/hurtbox.

---

¡Gracias por ayudar a forjar la niebla de **PUYU**! 🌫️

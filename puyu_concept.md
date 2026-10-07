# Documento de Concepto: PUYU

## Resumen General
*   **Título:** Puyu (significa "niebla" en quechua).
*   **Género:** Exploración, Aventura, Plataformas 3D.
*   **Motor:** Godot 4 (Renderizador: Compatibilidad).
*   **Inspiración de Gameplay:** La agilidad y movimiento vertical de *Sekiro*.
*   **Inspiración Visual:** Estética retro de PS2 (Silent Hill, Shadow of the Colossus).

## Dirección de Arte y Estética (PS2 Low Poly)
*   **Visuales:** Modelos low-poly, texturas de baja resolución (sin filtro bilineal), vertex jitter (temblor de polígonos intencional).
*   **Atmósfera:** Una densa niebla constante ("Puyu") para limitar la visión, dar melancolía y justificar las limitaciones técnicas.
*   **Colores:** Tonos tierra (adobe, piedra), ichu (paja andina) desaturado, calamina oxidada, grises y azules fríos.
*   **Ambientación:** Un pueblo abandonado y vertical en la sierra peruana. Callejones de piedra, casas de adobe, techos de calamina, pircas y puentes colgantes.

## Mecánicas Principales (Exploración Ágil)
El juego no se enfoca en el combate, sino en la fluidez del movimiento y la tensión del entorno.
*   **Parkour y Escalada:** Agarre a salientes, saltos entre tejados y muros de arquitectura incaica.
*   **Herramienta de Impulso (Grappling):** Una mecánica inspirada en el gancho de Sekiro (puede ser una guaraca mística o uso del viento andino) para cruzar grandes vacíos verticales.
*   **Tensión y Sigilo:** Evitar hacer ruido o caer en plataformas precarias. Evadir presencias sutiles basadas en mitología andina (Mukis, Condenados) escondidos en la niebla.

## Estructura del Mundo
*   **Diseño de Nivel:** Pequeño, pero muy denso y con alta verticalidad. Laderas de montañas empinadas.
*   **Puntos de Guardado/Descanso:** "Apachetas" (montículos de piedras sagradas). Al usarlas puede cambiar sutilmente el ciclo de día/noche o la densidad de la niebla.
*   **Narrativa:** Ambiental. Sin NPCs convencionales; la historia se cuenta a través de altares abandonados, ofrendas y el diseño de las casas.

## Objetivos Inmediatos de Desarrollo (Para la IA)
1.  Configurar un `CharacterBody3D` con físicas de movimiento fluido (correr, saltar, gravedad ajustada).
2.  Implementar cámara en tercera persona que siga al jugador.
3.  Establecer la configuración global de renderizado (niebla, shaders de PS2).
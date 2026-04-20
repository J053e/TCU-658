# TCU-658

Base de proyecto para el juego educativo **English Passport: Here I Am!**, orientado a estudiantes de secundaria que están aprendiendo inglés.

## Stack recomendado

- **Motor:** Godot 4.x
- **Lenguaje:** GDScript
- **Objetivo:** base portable para Windows.

## Estructura creada

- `project.godot`: configuración base del proyecto.
- `scenes/`: escenas principales del flujo.
- `scripts/`: lógica base (estado global, menú, mapa, zona, pantalla final).
- `data/game_content.json`: contenido inicial de las 5 zonas basado en tu documento.

## Flujo actual (esqueleto)

1. Menú principal
2. Mapa de zonas (5 zonas)
3. Escena genérica por zona con lista de minijuegos (placeholder)
4. Sistema de sellos (stamps) y guardado local
5. Pantalla final de progreso
6. UI construida por código para evitar incompatibilidades entre versiones

## Cómo abrir

1. Instala Godot 4.x.
2. Abre Godot y selecciona **Import**.
3. Elige esta carpeta: `C:\Users\JosePC\Desktop\TCU\TCU-658`.
4. Ejecuta la escena principal.

## Exportación portable en Godot 4

1. En Godot: `Project > Install Export Templates`.
2. En `Project > Export...` agrega `Windows Desktop` y exporta tu build portable.
3. Distribuye la carpeta exportada con su `.exe` y archivos del juego.

## Nota importante sobre 32 bits

- En Godot 4, el soporte oficial de exportación está centrado en 64 bits.
- Si necesitas soporte **garantizado** para Windows 32 bits, normalmente se usa Godot 3.x o plantillas/compilación personalizada.

## Próximos pasos

1. Implementar minijuegos reales zona por zona usando el JSON como fuente.
2. Añadir audio, imágenes e interfaz visual final.
3. Integrar evaluación por respuestas correctas/incorrectas y retroalimentación pedagógica.

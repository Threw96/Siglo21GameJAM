# Documentacion del proyecto Siglo21Jam

Este documento explica como funciona el codigo actual del juego, como se conectan las escenas principales y que partes se pueden modificar o mejorar.

## Resumen general

El proyecto es un juego 2D en Godot donde el jugador se mueve, dispara automaticamente al enemigo mas cercano, recibe daño si un enemigo se acerca, mata enemigos, recoge gemas de experiencia y sube de nivel. Al subir de nivel, el juego se pausa y aparece un menu con 3 mejoras seleccionables.

El ciclo principal es:

1. El nivel instancia al `Player`, enemigos iniciales y un `spawn`.
2. El `spawn` crea enemigos cada cierto tiempo.
3. El `Player` detecta enemigos cercanos con un `Area2D`.
4. Cada cierto tiempo, el `Player` dispara una bala al enemigo mas cercano.
5. La bala viaja en linea recta y aplica el daño actual del jugador.
6. Cuando el enemigo muere, suelta una gema.
7. Si el jugador pasa por encima de la gema, recibe experiencia.
8. Al subir de nivel, `Stats` cura al jugador al maximo y emite una señal.
9. El `Player` abre el menu de mejoras.
10. El menu pausa el juego hasta que se elige una mejora.

## Notas del GDD

El GDD compartido define el juego como `pipes n gears`: un juego 2D con ambientacion steampunk/industrial, ingenieros, mecanicos, electricistas, robots y supervivencia por tiempo. El personaje debe moverse, juntar gemas, subir de nivel, recibir mejoras, tener barra de vida, usar armas y morir.

Controles definidos por el GDD:

- Movimiento con `ASDW`.
- Seleccion de menus con click o enter.

Mecanicas alineadas actualmente:

- Movimiento del personaje.
- Recoleccion de gemas.
- Subida de nivel.
- Tres mejoras al azar y eleccion de una.
- Barra de vida.
- Enemigos que se acercan al jugador.

Ideas futuras del GDD:

- Supervivencia de 20 minutos.
- Jefe final al terminar el tiempo.
- Enemigos/minijefes con ataques especiales.
- Armas steampunk como llave boomerang, rayos o variantes por personaje.

## Estructura importante

### Scripts

- `Assets/Scripts/Stats.gd`: recurso de estadisticas, vida, experiencia, nivel y buffs.
- `Assets/Scripts/stat_buff.gd`: recurso que representa una mejora aplicada a un stat.
- `Assets/Scripts/player.gd`: movimiento, disparo, daño recibido, experiencia y level up del jugador.
- `Assets/Scripts/enemy.gd`: clase base para enemigos, vida, daño recibido, muerte y drop de gemas.
- `Assets/Scripts/miniboss_enemy.gd`: clase base para minijefes con ataque especial.
- `Assets/Scripts/boss_enemy.gd`: clase base para jefes con fases.
- `Assets/Scripts/boss_robot.gd`: jefe robot lento, resistente y de mucho daño.
- `enemigo1.gd`: IA especifica del enemigo BabyAllien, movimiento y ataque al jugador.
- `Assets/Scripts/weapon.gd`: clase base de armas.
- `Assets/Scripts/projectile_weapon.gd`: arma de proyectiles usada por el player.
- `Assets/Scripts/bullet_example.gd`: proyectil que viaja recto y daña enemigos.
- `Assets/Scripts/gema.gd`: gema recolectable que entrega experiencia.
- `Assets/Scripts/spawn.gd`: spawner de enemigos.
- `Assets/Scripts/upgrade_menu.gd`: menu de seleccion de mejoras al subir de nivel.
- `Assets/Scripts/hud.gd`: HUD de vida, experiencia y nivel.
- `Assets/Scripts/Global.gd`: singleton/autoload con referencia global al jugador.

### Escenas

- `Scenes/Nivel1/level_1.tscn`: escena principal del nivel.
- `Scenes/Player.tscn`: escena del jugador.
- `Scenes/enemigo1.tscn`: escena del enemigo `BabyAllien`.
- `Scenes/BossRobot.tscn`: escena del jefe robot.
- `Scenes/bullet_example.tscn`: escena del proyectil.
- `Scenes/Gema.tscn`: escena de la gema de experiencia.
- `Scenes/UpgradeMenu.tscn`: escena del menu de mejoras.
- `Scenes/HUD.tscn`: escena de interfaz durante la partida.
- `Scenes/Menu.tscn`: menu existente del proyecto.
- `Scenes/CharacterSelectMenu.tscn`: seleccion de personaje antes de iniciar la partida.

### Recursos

- `Assets/Resources/Player_stats.tres`: stats base del jugador.
- `Assets/Resources/maxHealth_statCurve.tres`: curva de vida maxima por nivel.
- `Assets/Resources/defense_statCurve.tres`: curva de defensa por nivel.
- `Assets/Resources/attack_statCurve.tres`: curva de ataque por nivel.

## Sistema de stats

Archivo: `Assets/Scripts/Stats.gd`

`Stats` es un `Resource`, no un nodo de escena. Esto permite crear recursos `.tres` editables desde el inspector de Godot.

Define estos stats:

- `base_max_health`: vida maxima base.
- `base_defense`: defensa base.
- `base_attack`: ataque base.
- `base_move_speed`: velocidad base de movimiento.
- `base_fire_rate`: disparos por segundo base.
- `experience`: experiencia acumulada.
- `level`: nivel calculado automaticamente desde la experiencia.
- `current_max_health`: vida maxima actual, despues de curvas y buffs.
- `current_defense`: defensa actual.
- `current_attack`: ataque actual.
- `current_move_speed`: velocidad actual del jugador.
- `current_fire_rate`: disparos por segundo actuales.
- `health`: vida actual.

### Nivel y experiencia

El nivel se calcula con:

```gdscript
floor(max(1.0, sqrt(experience / BASE_LEVEL_EXP) + 0.5))
```

Esto significa que el crecimiento de experiencia es progresivo: cada nivel requiere mas experiencia que el anterior.

Funciones utiles:

- `add_experience(amount)`: suma experiencia.
- `get_experience_for_level(target_level)`: devuelve cuanta experiencia total pide un nivel.
- `get_experience_to_next_level()`: devuelve cuanta experiencia falta para subir.
- `on_experience_set(new_value)`: setter de `experience`; detecta si subio el nivel.

Cuando el nivel cambia:

1. Recalcula stats.
2. Cura al jugador al maximo.
3. Emite `leveled_up(new_level, old_level)`.

### Vida

La vida se guarda en `health`.

Cuando cambia `health`, se llama a `_on_health_set()`:

- Limita la vida entre `0` y `current_max_health`.
- Emite `health_changed`.
- Si llega a `0`, emite `health_depleted`.

Esto permite conectar UI de barra de vida o logica de muerte sin duplicar codigo.

### Daño y defensa

El daño al jugador se centraliza en `Stats.take_damage(raw_damage)`.

Flujo:

1. Recibe daño bruto.
2. Calcula daño final con `get_damage_after_defense()`.
3. Resta el daño final a `health`.
4. Emite `damage_taken(raw_damage, final_damage)`.
5. Devuelve el daño final aplicado.

Actualmente la defensa reduce daño plano:

```gdscript
maxf(raw_damage - current_defense, 1.0)
```

Eso asegura que un golpe valido siempre haga al menos `1` de daño. Si mas adelante queres defensa porcentual, este es el lugar para cambiar la formula.

El sistema actual tambien soporta reduccion porcentual global, resistencias por tipo de daño (`PHYSICAL`, `ELECTRIC`, `FIRE`), invulnerabilidad breve con `set_invulnerable()`, y señales de feedback como `damage_taken` y `damage_blocked`.

### Curvas de stats

`Stats.gd` usa `STAT_CURVES` para modificar los stats segun el nivel.

La funcion `_get_curve_multiplier()` normaliza las curvas para que en nivel 1 el multiplicador sea `1.0`. Gracias a eso, si `base_max_health` es `5`, la vida en nivel 1 empieza en `5` y no en un valor inflado por la curva.

Para modificar el escalado:

1. Abrir una curva en `Assets/Resources`.
2. Cambiar sus puntos desde el editor.
3. Probar como cambia el stat al subir de nivel.

## Sistema de buffs/mejoras

Archivo: `Assets/Scripts/stat_buff.gd`

`StatBuff` es un `Resource` simple que representa una mejora.

Campos:

- `stat`: stat afectado. Usa `Stats.BuffableStats`.
- `buff_amount`: cantidad del buff.
- `buff_type`: tipo de buff.

Tipos disponibles:

- `ADD`: suma un valor plano. Ejemplo: `+15 vida maxima`.
- `MULTIPLY`: suma un multiplicador. Ejemplo: `+0.15 ataque` equivale a `+15%`.

Ejemplo:

```gdscript
StatBuff.new(Stats.BuffableStats.ATTACK, 0.15, StatBuff.BuffType.MULTIPLY)
```

Ese buff aumenta el ataque actual en 15%.

### Como se aplican

`Stats.add_buff(buff)` agrega el buff a `stat_buffs` y recalcula stats.

`Stats.recalculate_stats()`:

1. Calcula stats base escalados por curva.
2. Aplica multiplicadores.
3. Aplica sumas planas.

Para agregar nuevos stats modificables:

1. Agregar el stat al enum `BuffableStats`.
2. Agregar una variable base, por ejemplo `base_speed`.
3. Agregar una variable actual, por ejemplo `current_speed`.
4. Agregar su curva a `STAT_CURVES`.
5. Usar el nombre siguiendo el patron `current_` + nombre del enum en minuscula.

## Player

Archivo: `Assets/Scripts/player.gd`

El `Player` extiende `CharacterBody2D` y tiene `class_name Player`, lo que permite usarlo como tipo en otros scripts.

Responsabilidades:

- Guardar referencia global en `Global.Player`.
- Moverse con inputs.
- Buscar enemigos cercanos.
- Disparar automaticamente.
- Recibir daño.
- Recibir experiencia.
- Generar mejoras al subir de nivel.
- Abrir el menu de mejoras.

### Movimiento

En `_physics_process()` usa:

```gdscript
Input.get_vector("izquierda", "derecha", "arriba", "abajo")
```

Los inputs estan definidos en `project.godot`:

- `W`: arriba.
- `S`: abajo.
- `A`: izquierda.
- `D`: derecha.

La direccion se multiplica por `speed` y luego se llama `move_and_slide()`.

### Disparo automatico

La escena `Player.tscn` tiene un `Timer` llamado `Weapon/cd`. Cuando hace timeout llama a `_on_cd_timeout()`, que ejecuta `Shot()`.

`Shot()`:

1. Toma los cuerpos dentro del `Area2D` del jugador.
2. Filtra los que estan en grupo `"Enemy"`.
3. Busca el enemigo mas cercano.
4. Rota el arma con `look_at()`.
5. Instancia una bala.
6. La agrega al padre del jugador, normalmente el nivel.
7. Llama `launch()` en la bala.
8. Le pasa el daño desde `stats.current_attack`.

La bala se agrega al nivel y no al jugador para evitar que herede el movimiento del jugador. Si se agregara como hija del jugador, pareceria curvarse al moverse el player.

El disparo actual esta separado en un sistema de armas: `Player` junta sus hijos que heredan de `Weapon` y llama `weapon.tick(delta, self, stats)`. El arma actual es `ProjectileWeapon`, que busca el enemigo mas cercano, instancia proyectiles y usa stats como daño, rango, fire rate y cantidad de proyectiles.

### Recibir experiencia

`add_experience(amount)` delega en:

```gdscript
stats.add_experience(amount)
```

Tambien imprime experiencia, nivel y experiencia faltante para debug.

Este metodo es usado por la gema. La gema no necesita saber que el cuerpo es exactamente `Player`; solo revisa si tiene `add_experience()`.

### Subir de nivel

Cuando `Stats` emite `leveled_up`, el player ejecuta `_on_stats_leveled_up()`.

Flujo:

1. Crea 3 mejoras con `_build_upgrade_choices(new_level)`.
2. Guarda las mejoras en `pending_upgrade_choices`.
3. Emite `upgrade_choices_ready`.
4. Instancia el menu con `_show_upgrade_menu(new_level)`.

Mejoras actuales:

- Vida maxima plana.
- Ataque porcentual.
- Defensa plana.
- Velocidad de movimiento porcentual.
- Velocidad de disparo porcentual.

Para modificar estas mejoras, editar `_build_upgrade_choices()`.

Actualmente se conserva el pool completo de mejoras y se eligen 3 opciones al azar con `shuffle()`. Esto evita que las opciones sean siempre las mismas.

Durante una partida, el jugador puede especializarse en un maximo de 4 stats distintos. Cada stat elegido tiene un limite temporal de 3 elecciones. Cuando un stat llega a ese limite, deja de aparecer en el pool; cuando ya hay 4 stats distintos elegidos, el menu solo ofrece mejoras de esos stats hasta que se agoten.

Si el jugador sube varios niveles de golpe, las pantallas de mejora se encolan: solo puede haber un menu activo, el juego permanece pausado, y al elegir una mejora aparece la siguiente seleccion pendiente.

### Elegir mejora

`choose_upgrade(choice_index)`:

1. Valida que el indice exista.
2. Aplica el buff con `stats.add_buff()`.
3. Limpia `pending_upgrade_choices`.

El menu llama esta funcion cuando el jugador elige una opcion.

Si la mejora elegida afecta `MAX_HEALTH`, `Player` pide que `Stats` cure al maximo despues de recalcular. Asi el jugador queda con la nueva vida maxima, incluyendo la mejora.

### Recibir daño

`TakeDamage(damage)`:

1. Verifica que existan stats.
2. Reinicia la particula `CPUParticles2D`.
3. Llama `stats.take_damage()`.
4. El calculo de defensa ocurre dentro de `Stats`.
5. Si la vida llega a 0, llama `Die()`.

`Die()` elimina al player con `queue_free()`.

Los logs de daño solo aparecen si el modo debug esta activo.

## Clase base Enemy

Archivo: `Assets/Scripts/enemy.gd`

`Enemy` extiende `CharacterBody2D` y concentra la logica compartida por enemigos.

Variables exportadas:

- `speed`: velocidad de movimiento.
- `max_health`: vida maxima.
- `experience_value`: experiencia que dara la gema al morir.
- `gem_scene`: escena de la gema que dropea.
- `drop_gem_chance`: probabilidad de soltar gema.
- `damage`: daño que aplica al jugador.
- `stats`: recurso opcional para enemigos con stats propios.
- `phase_health_ratios`: umbrales de fase para jefes o enemigos especiales.

Responsabilidades:

- Agregarse al grupo `"Enemy"`.
- Inicializar `health`.
- Recibir daño con `TakeDamage()`.
- Morir con `_die()`.
- Soltar gema con `_drop_gem()`.

Para crear un enemigo nuevo, heredar de `Enemy` y escribir solo su comportamiento particular.

Tambien hay clases listas para escenas futuras: `MiniBossEnemy` agrega ataque especial con cooldown, y `BossEnemy` usa fases para escalar daño y velocidad.

## Enemigo BabyAllien

Archivo: `enemigo1.gd`

`BabyAllien` hereda de `Enemy` y tiene `class_name BabyAllien`.

### Movimiento y ataque

En `_physics_process()`:

- Si `Global.Player` es `null`, no hace nada.
- Si `canAttack` es `true`, llama `Attack()`.
- Si no, llama `Move()`.

`Move()` calcula direccion hacia el player y se mueve con `move_and_slide()`.

`Attack()`:

1. Revisa si el timer esta en cooldown.
2. Llama `Global.Player.TakeDamage(damage)`.
3. Reinicia el timer.

`canAttack` cambia segun el `Area2D` del enemigo:

- `_on_area_2d_body_entered()`: si entra el player, puede atacar.
- `_on_area_2d_body_exited()`: si sale el player, deja de atacar.

### Recibir daño y morir

BabyAllien hereda `TakeDamage()`, `_die()` y `_drop_gem()` desde `Enemy`.

Para crear enemigos nuevos:

1. Crear una nueva escena parecida a `enemigo1.tscn`.
2. Crear un script que haga `extends Enemy`.
3. Ajustar `speed`, `max_health`, `damage` y `experience_value`.
4. Cambiar el preload en `spawn.gd` si queres que el spawner use ese enemigo.

## Bala/proyectil

Archivo: `Assets/Scripts/bullet_example.gd`

La bala extiende `CharacterBody2D`.

Variables:

- `Direction`: direccion fija del disparo.
- `speedBullet`: velocidad.
- `damageAmount`: daño que aplicara.

### Launch

`launch(start_position, target_position, attack_damage)` inicializa la bala:

1. Posiciona la bala en `start_position`.
2. Calcula una direccion hacia `target_position`.
3. Guarda el daño recibido desde el player.
4. Rota la bala para mirar hacia la direccion.

Despues de eso, la bala ya no sigue al enemigo. Sigue una trayectoria recta.

### Movimiento

En `_physics_process()`:

```gdscript
velocity = Direction.normalized() * speedBullet
move_and_slide()
```

### Impacto

Cuando su `Area2D` detecta un cuerpo:

- Si esta en grupo `"Enemy"`, llama `body.TakeDamage(damageAmount)`.
- Luego se destruye con `queue_free()`.

El `Timer` de la escena destruye la bala despues de 3 segundos para evitar balas infinitas.

Mejoras posibles:

- Usar `Area2D` como raiz en vez de `CharacterBody2D`, si la bala no necesita fisica de cuerpo.
- Agregar pierce, criticos o knockback.
- Agregar collision layers diferentes para no golpear cosas no deseadas.

## Gema de experiencia

Archivo: `Assets/Scripts/gema.gd`

La gema extiende `Area2D`.

Variable:

- `experience_amount`: experiencia que entrega al recolectarse.

En `_ready()` conecta su señal `body_entered` a `_on_body_entered()`.

Cuando un cuerpo entra:

1. Revisa si el cuerpo tiene metodo `add_experience`.
2. Si lo tiene, llama `body.add_experience(experience_amount)`.
3. Se elimina con `queue_free()`.

La escena `Scenes/Gema.tscn` tiene:

- Root `Area2D`.
- `collision_mask = 4`, para detectar al player.
- `CollisionShape2D` para la zona de recoleccion.

Para cambiar cuanta experiencia da:

- Cambiar `experience_value` en el enemigo.
- O cambiar `experience_amount` por defecto en la gema.

La gema ahora tiene recoleccion magnetica: si el player esta dentro de `stats.current_pickup_range`, se mueve hacia el personaje usando `attraction_speed`.

## Menu de mejoras

Archivos:

- `Assets/Scripts/upgrade_menu.gd`
- `Scenes/UpgradeMenu.tscn`

El menu se instancia cuando el player sube de nivel.

### Pausa

En `_ready()`:

```gdscript
process_mode = Node.PROCESS_MODE_ALWAYS
get_tree().paused = true
```

Esto pausa el juego, pero permite que el menu siga recibiendo input.

Cuando se elige una mejora:

```gdscript
get_tree().paused = false
queue_free()
```

### Setup

`setup(_player, _choices, level)` recibe:

- El player que debe recibir la mejora.
- La lista de 3 buffs.
- El nivel nuevo para mostrar en pantalla.

### Controles

Se puede elegir con:

- Click del mouse.
- `ui_up` y `ui_down` para cambiar opcion enfocada.
- `ui_accept`, `Enter` o `Space` para confirmar.

Nota: Godot ya trae acciones `ui_up`, `ui_down` y `ui_accept` por defecto. En este proyecto tambien hay una accion `enter`, pero el menu usa `ui_accept` y chequeo directo de `KEY_ENTER`/`KEY_SPACE`.

### Texto de las opciones

`_get_choice_text(choice)` convierte un `StatBuff` en texto:

- `ADD`: `+15 MAX HEALTH`.
- `MULTIPLY`: `+15% ATTACK`.

Para cambiar el estilo visual, editar `Scenes/UpgradeMenu.tscn`.

Para cambiar nombres mas lindos, editar `_get_choice_text()`.

## Menu de pausa y muerte

Archivos:

- `Assets/Scripts/pause_menu.gd`
- `Scenes/PauseMenu.tscn`
- `Assets/Scripts/death_menu.gd`
- `Scenes/DeathMenu.tscn`

Durante la partida, `Player.gd` escucha `Escape` y `Enter`. Si no hay menu de mejoras activo, instancia `PauseMenu.tscn`, pausa el arbol y muestra un panel lateral izquierdo.

El panel de pausa muestra hasta 4 espacios de mejoras. Esos espacios se llenan con los stats distintos que el jugador eligio durante la partida y cada uno se muestra en formato `actual/3`. Si todavia no se eligieron 4 tipos distintos, los espacios restantes aparecen vacios.

Si la vida llega a 0, `Player.Die()` detiene la run, limpia UI persistente agregada al root y carga `Scenes/DeathMenu.tscn`. Esa pantalla muestra `LA MUERTE HA ENCONTRADO` y un boton `Volver` que regresa a `Scenes/Menu.tscn`.

## HUD de partida

Archivos:

- `Assets/Scripts/hud.gd`
- `Scenes/HUD.tscn`
- `Scenes/Player.tscn`

El HUD muestra informacion importante durante la partida:

- Barra de experiencia arriba de la pantalla.
- Texto de nivel en la esquina superior izquierda.
- Barra de vida debajo del personaje.
- Tiempo sobrevivido.
- Contador de enemigos derrotados.

### Barra de vida del player

La barra de vida es un `ProgressBar` llamado `HealthBar` dentro de `Scenes/Player.tscn`.

`Player.gd` se conecta a:

```gdscript
stats.health_changed.connect(_on_stats_health_changed)
```

Cada vez que cambia la vida, `_update_health_bar()` ajusta:

- `health_bar.max_value`
- `health_bar.value`

Como la barra es hija del player, se mueve junto con el personaje.

### Barra de experiencia y nivel

`Player.gd` instancia `Scenes/HUD.tscn` al iniciar:

```gdscript
_show_hud.call_deferred()
```

El HUD recibe el recurso `Stats` con `setup(stats)`.

`hud.gd` se conecta a:

- `stats.experience_changed`
- `stats.leveled_up`

La barra de experiencia usa:

- `get_current_level_experience()`
- `get_next_level_required_experience()`

El texto de nivel usa:

```gdscript
stats.level
```

Los numeros de experiencia (`0 / 225 XP`) solo se muestran si el modo debug esta activo.

Para cambiar posicion, colores o tamano del HUD, editar `Scenes/HUD.tscn`.

## Modo debug

El modo debug se activa con la variable de entorno:

```text
SIGLO21_DEBUG=1
```

Valores aceptados:

- `1`
- `true`
- `yes`
- `on`

`Global.gd` lee esta variable al iniciar y guarda el resultado en `Global.debug_enabled`.

Para escribir mensajes de debug se usa:

```gdscript
Global.debug_log("mensaje")
```

Si debug esta apagado, no imprime nada.

Actualmente el modo debug:

- Muestra los numeros exactos de experiencia en el HUD.
- Activa logs de experiencia, vida, muerte y opciones de nivel.

En Windows PowerShell, para probar desde consola:

```powershell
$env:SIGLO21_DEBUG="1"
godot
```

Si abrís desde Steam, conviene crear la variable de entorno de usuario en Windows y reiniciar Steam para que Godot la herede.

Tambien se puede activar desde un archivo `.env` en la raiz del proyecto. Formatos aceptados:

```text
SIGLO21_DEBUG=1
```

o estilo PowerShell:

```powershell
$env:SIGLO21_DEBUG="1"
```

Si existe `.env`, `Global.gd` lo lee al iniciar y usa ese valor antes de consultar `OS.get_environment()`.

## Spawner

Archivo: `Assets/Scripts/spawn.gd`

El spawner instancia enemigos cada vez que recibe timeout del timer del nivel.

Usa estos nodos hijos:

- `x1` y `x2`: rango horizontal.
- `y1` y `y2`: rango vertical.

Genera una posicion aleatoria:

```gdscript
Vector2(
	randf_range($x1.global_position.x, $x2.global_position.x),
	randf_range($y1.global_position.y, $y2.global_position.y)
)
```

Luego agrega el enemigo como hijo del spawner y le asigna posicion global.

El spawner ahora escala con `Global.survived_time`: reduce el tiempo entre oleadas, aumenta cantidad de enemigos, escala vida/daño/experiencia y puede generar enemigos fuera de camara con `spawn_outside_camera`.

Cada 5 minutos intenta spawnear un jefe desde `Scenes/BossRobot.tscn`. Mientras el jefe esta vivo, el spawner no crea enemigos normales. Cuando el jefe muere, se reanuda el spawn normal hasta el proximo bloque de 5 minutos.

Para modificar spawn:

- Cambiar `wait_time` del `Timer` en `level_1.tscn`.
- Cambiar las posiciones de los markers.
- Cambiar `enemigo` por otra escena.
- Agregar logica para aumentar dificultad con el tiempo.

## Global singleton

Archivo: `Assets/Scripts/Global.gd`

`Global` esta registrado como autoload en `project.godot`.

Actualmente guarda:

```gdscript
var Player: Player = null
```

El player se registra en `_ready()`:

```gdscript
Global.Player = self
```

Los enemigos usan `Global.Player` para perseguir y atacar al jugador.

Mejora recomendada: si el juego crece, evitar depender demasiado de `Global` y usar grupos o señales para desacoplar sistemas.

## Pantalla inicial

Archivo: `Scenes/Menu.tscn`

El proyecto arranca en el menu inicial. `Iniciar partida` carga `Scenes/CharacterSelectMenu.tscn`; `Salir` cierra el juego. El script asociado es `Assets/Scripts/main_menu.gd`.

## Seleccion de personaje

Archivos:

- `Scenes/CharacterSelectMenu.tscn`
- `Assets/Scripts/character_select_menu.gd`
- `personajes.png`

Esta pantalla aparece entre el menu inicial y `Scenes/Nivel1/level_1.tscn`. Usa `personajes.png` como atlas y recorta los tres personajes con `AtlasTexture`.

Al elegir un personaje:

1. Guarda el indice en `Global.selected_character_id`.
2. Guarda el nombre en `Global.selected_character_name`.
3. Carga `Scenes/Nivel1/level_1.tscn`.

La seleccion cambia el sprite visible del `Player`. `Player.gd` lee `Global.selected_character_id`, recorta `personajes.png` con `AtlasTexture` y reemplaza la textura del nodo `OneHanded`.

Tambien queda preparada para futuras diferencias de stats o armas.

## Escena principal Level 1

Archivo: `Scenes/Nivel1/level_1.tscn`

Contiene:

- Un enemigo inicial.
- El spawner.
- Markers de rango de spawn.
- Un timer de spawn.
- El player.

El timer del nivel llama:

```gdscript
spawn._on_timer_timeout()
```

El `Player` de esta escena sobreescribe sus stats con un subresource local:

```text
base_max_health = 10.0
```

Esto significa que aunque `Player_stats.tres` tenga `base_max_health = 5.0`, en `level_1.tscn` el player puede arrancar con otro valor. Si queres usar siempre el recurso externo, elimina la sobreescritura local del `stats` en el inspector.

## Capas y grupos

Grupos definidos en `project.godot`:

- `Player`
- `Enemy`

Capas importantes observadas:

- Player: `collision_layer = 4`.
- Enemy: `collision_layer = 2`.
- Gema: `collision_mask = 4`, detecta al player.
- Bala: `Area2D collision_mask = 2`, detecta enemigos.
- Area de deteccion del player: `collision_mask = 2`, detecta enemigos.

Si algo no detecta colisiones, revisar:

1. Que el nodo tenga `CollisionShape2D`.
2. Que la shape no este deshabilitada.
3. Que el layer del objetivo coincida con el mask del detector.
4. Que el cuerpo este en el grupo esperado.

## Como modificar cosas comunes

### Cambiar vida inicial del jugador

Opcion 1: editar `Assets/Resources/Player_stats.tres`.

Opcion 2: editar el subresource local del player en `Scenes/Nivel1/level_1.tscn`.

Importante: si el nivel sobreescribe el recurso, ese valor gana sobre el `.tres`.

### Cambiar daño del jugador

Editar `base_attack` en el recurso `Stats` usado por el player.

El daño aplicado a enemigos sale de:

```gdscript
stats.current_attack
```

### Cambiar velocidad del jugador

Editar `speed` en `Scenes/Player.tscn` o en la instancia del player dentro del nivel.

### Cambiar daño del enemigo

Editar `damage` en `Scenes/enemigo1.tscn`.

### Cambiar vida del enemigo

Editar `max_health` en `Scenes/enemigo1.tscn`.

### Cambiar experiencia que da un enemigo

Editar `experience_value` en `Scenes/enemigo1.tscn`.

### Cambiar frecuencia de disparo

Editar `wait_time` del timer `Weapon/cd` en `Scenes/Player.tscn`.

### Cambiar rango de disparo

Editar el radio del `CollisionShape2D` dentro de `Player/Area2D`.

### Cambiar velocidad de bala

Editar `speedBullet` en `Scenes/bullet_example.tscn` o en `bullet_example.gd`.

### Cambiar mejoras de nivel

Editar `_build_upgrade_choices()` en `Assets/Scripts/player.gd`.

Ejemplo para agregar mas ataque:

```gdscript
StatBuff.new(Stats.BuffableStats.ATTACK, 0.25, StatBuff.BuffType.MULTIPLY)
```

### Cambiar el menu de mejoras

Editar `Scenes/UpgradeMenu.tscn` para layout, colores, texto y botones.

Editar `Assets/Scripts/upgrade_menu.gd` para comportamiento.

## Ideas de mejora

### 1. Profundizar daño y defensa

El daño y la defensa ya estan centralizados en `Stats.take_damage()`. Proximas mejoras posibles:

- Defensa porcentual en vez de defensa plana.
- Tipos de daño, por ejemplo fisico, electrico o fuego.
- Invulnerabilidad breve despues de recibir daño.
- Señales de feedback para sonido, camara o animaciones.

### 2. Expandir clases de enemigos

`Enemy.gd` ya existe como clase base y `BabyAllien` hereda de ella. Proximas mejoras posibles:

- Enemigos con stats propios usando `Stats`.
- Enemigos que no dropeen gemas siempre.
- Minijefes con ataques especiales.
- Jefes con fases.

### 3. Mejorar el sistema de mejoras

Ahora el pool de mejoras puede crecer, pero cada partida limita al jugador a 4 tipos distintos y cada uno puede elegirse como maximo 3 veces.

Se puede mejorar con:

- Pool de mejoras posibles.
- Eleccion aleatoria sin repetir.
- Rarezas.
- Mejoras desbloqueables.
- Mejoras de arma.
- Mejoras de velocidad, cooldown, cantidad de proyectiles, rango, magnetismo de gemas.

### 3.1. Preparar sistema de armas futuro

El GDD menciona armas steampunk como llave boomerang, rayos y variantes para ingeniero, mecanico o electricista. Para implementarlo sin romper el player, conviene separar el arma en una escena propia.

Estructura recomendada:

- `Weapon.gd`: clase base con cooldown, daño, rango y metodo `attack()`.
- `ProjectileWeapon.gd`: arma que instancia proyectiles.
- `BoomerangWeapon.gd`: arma que lanza una llave que vuelve.
- `LaserWeapon.gd`: arma de rayo continuo o disparo instantaneo.

El `Player` deberia tener una lista de armas y llamar algo como:

```gdscript
for weapon in weapons:
	weapon.try_attack(stats)
```

De esta forma las mejoras futuras pueden afectar:

- Daño global.
- Velocidad de disparo global.
- Cantidad de proyectiles.
- Duracion de lasers.
- Tamaño de area.
- Armas nuevas desbloqueables.

### 4. Agregar UI permanente

Se puede crear una HUD con:

- Barra de vida.
- Barra de experiencia.
- Nivel actual.
- Tiempo sobrevivido.
- Contador de enemigos derrotados.

`Stats` ya emite `health_changed` y `leveled_up`, asi que es facil conectarla.

### 5. Recoleccion magnetica de gemas

Ahora la gema solo se recolecta si el player pasa encima.

Una mejora interesante seria que al estar cerca, la gema viaje hacia el jugador. Para eso:

- Agregar un area de atraccion.
- En `gema.gd`, si detecta al player, moverse hacia el.
- Mantener la recoleccion al entrar en contacto.

### 6. Balancear el spawn

El spawner actualmente usa un timer fijo.

Se puede escalar dificultad con:

- Menor `wait_time` con el tiempo.
- Mas enemigos por oleada.
- Enemigos mas fuertes por minuto.
- Spawn fuera de camara.

### 7. Reemplazar prints por UI/debug controlado

Hay prints utiles para desarrollo:

- XP del player.
- Vida del player.
- Mejoras disponibles.

Cuando el juego este mas avanzado, conviene:

- Mover info a HUD.
- O usar una variable `debug_enabled`.

## Problemas comunes y solucion

### La gema no se recolecta

Revisar:

- `Gema` debe ser `Area2D`.
- Debe tener `CollisionShape2D`.
- Su `collision_mask` debe detectar el layer del player.
- El player debe tener metodo `add_experience()`.

### El enemigo no recibe daño

Revisar:

- El enemigo debe estar en grupo `"Enemy"`.
- La bala debe detectar el layer del enemigo.
- El enemigo debe tener metodo `TakeDamage()`.

### La bala se curva

La bala debe agregarse al nivel, no como hija del player.

En `Player.Shot()` se usa:

```gdscript
parent.add_child(b)
```

Si se usa `add_child(b)` dentro del player, la bala hereda el movimiento del jugador.

### El menu no responde cuando el juego esta pausado

Revisar:

- `UpgradeMenu` debe tener `process_mode = Node.PROCESS_MODE_ALWAYS`.
- Los botones tambien se configuran con `PROCESS_MODE_ALWAYS`.
- El menu debe estar agregado al arbol antes de pausar o debe procesar siempre.

### El player tiene mas vida de la esperada

Revisar si `level_1.tscn` esta sobreescribiendo el recurso `Stats` del player.

Tambien revisar las curvas de vida y que `_get_curve_multiplier()` siga normalizando nivel 1.

## Convenciones actuales

- Metodos de daño usan `TakeDamage` con mayuscula inicial.
- Grupos: `"Player"` y `"Enemy"`.
- El player se obtiene globalmente con `Global.Player`.
- El daño del player sale de `stats.current_attack`.
- La experiencia llega al player mediante `add_experience()`.
- Las mejoras se representan con `StatBuff`.

## Proximo paso recomendado

El siguiente paso mas natural seria probar balance en una partida completa: ritmo de spawn, daño recibido con defensa porcentual, fuerza de las rarezas y cuanto acelera el progreso la recoleccion magnetica.

extends CharacterBody2D

#Variable de velocidad a la que se mueve el personaje
@export var speed: float = 10  

#texto de prueba para control de version
func _ready() -> void:
	Global.Player = self
###Funcion de godot en la que se ejecutan las fisicas 
# - En este caso las direcciones estan mapeadas desde el proyecto:
# W = arriba , A= izquierda, D= derecha y S= abajo
# Luego multiplica la direccion por speed y nos da la velocidad hacia donde mover
###
func _physics_process(delta: float) -> void:
	var Direction := Input.get_vector("izquierda","derecha","arriba","abajo")
	
	velocity = Direction * speed
	
	move_and_slide()
	

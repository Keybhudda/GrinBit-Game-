extends CanvasLayer
@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal on_transition_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func transition():
	color_rect.visible = true
	animation_player.play("fade")

func _on_animation_finished(ani_name):
	if ani_name == "fade":
		on_transition_finished.emit()
		animation_player.play("fade2")
	elif ani_name == "fade2":
		color_rect.visible = false

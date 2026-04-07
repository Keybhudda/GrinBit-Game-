extends VBoxContainer

var sections = []

func _ready():
	#Collect all sections
	for child in get_children():
		sections.append(child)
		
		var btn = child.get_node("Button")
		btn.pressed.connect(_on_section_pressed.bind(child))
		
		#Hide all panels at start
		child.get_node("Panel").visible = false
		
func _on_section_pressed(section):
	for sec in sections:
		sec.get_node("Panel").visible = false
	
	section.get_node("Panel").visible = true
	

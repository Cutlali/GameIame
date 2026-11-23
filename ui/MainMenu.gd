extends Control

func _ready():
	$Content/Panel/Margin/VBox/StartButton.grab_focus()
	if OS.has_feature("HTML5"):
		$Content/Panel/Margin/VBox/QuitButton.hide()


func _on_StartButton_pressed():
	GS.reset_all_state()
	SceneTransitions.change_scene_to(GS.Intro)


func _on_QuitButton_pressed():
	get_tree().quit()

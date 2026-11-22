extends Control

func _ready():
	$Content/Panel/Margin/VBox/StartButton.grab_focus()

func _on_StartButton_pressed():
	GS.reset_all_state()
	SceneTransitions.change_scene_to(GS.Intro)
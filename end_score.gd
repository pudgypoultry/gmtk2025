extends Label

@export var scoreLabel : Label

func SetScore():
	text = "FINAL " + scoreLabel.text

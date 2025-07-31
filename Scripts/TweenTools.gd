extends Node

func TweenPosition(objectToTween, tween, desiredPosition, tweenWindow, transStyle = Tween.TRANS_SINE, easeStyle = Tween.EASE_IN_OUT):
	tween = create_tween().bind_node(objectToTween)
	tween.set_trans(transStyle)
	tween.set_ease(easeStyle)
	tween.tween_property(objectToTween, "position", desiredPosition, tweenWindow)


func TweenRotation(objectToTween, tween, desiredRotation, tweenWindow, transStyle = Tween.TRANS_SINE, easeStyle = Tween.EASE_IN_OUT):
	tween = create_tween().bind_node(objectToTween)
	tween.set_trans(transStyle)
	tween.set_ease(easeStyle)
	tween.tween_property(objectToTween, "rotation", desiredRotation, tweenWindow)


func TweenScale(objectToTween, tween, desiredScale, tweenWindow, transStyle = Tween.TRANS_SINE, easeStyle = Tween.EASE_IN_OUT):
	tween = create_tween().bind_node(objectToTween)
	tween.set_trans(transStyle)
	tween.set_ease(easeStyle)
	tween.tween_property(objectToTween, "scale", desiredScale, tweenWindow)

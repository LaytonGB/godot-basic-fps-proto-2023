extends Node3D
class_name Clip


var start: CharacterBody3D
var end: Node3D

@export var max_length: float = 5.0


func init(player: CharacterBody3D, fastening: Node3D):
	start = player
	end = fastening


func _process(delta):
	var start_pos := start.global_position
	var end_pos := end.global_position
	
	# set position
	var transition_vector := end_pos - start_pos
	var midpoint := start_pos + (transition_vector / 2)
	global_transform.origin = midpoint
	
	# set rotation
	look_at(end_pos)
	
	# set length
	var dist := start_pos.distance_to(end_pos)
	scale.z = dist
	print(dist)

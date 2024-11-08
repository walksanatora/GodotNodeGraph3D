@tool
extends StaticBody3D
class_name Graph3DPort

enum Side {
	Input,
	Output
}

## what side of the board is this port on (this determines how it limits connections
@export var side: Graph3DPort.Side = Side.Input
## the variable type of this port (changing can result in port color changing
@export var type: Graph3DVariable = preload("res://addons/node_graph_3D/defaults/Any.tres")
## a list of one (input) or more (output) connections
@export var connections: Array[Graph3DPort]


var _mesh: MeshInstance3D
var _collider: CollisionShape3D

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = type.display_color
	var meshi = BoxMesh.new()
	meshi.material = mat
	var mesh = MeshInstance3D.new()
	mesh.mesh = meshi
	add_child(mesh)
	_mesh = mesh
	
	var shape = BoxShape3D.new()
	var collision = CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	_collider = collision	
	
	scale = Vector3(0.1,0.1,0.1)

func connect_to(their: Graph3DPort) -> bool:
	#get our parents (so we can check any types)
	var my_parent = _get_g3dnode_parent()
	var their_parent = their._get_g3dnode_parent()
	
	# check if our types are valid to be connected to eachother
	var type_valid = (my_parent.any_type == type) or (their_parent.any_type == their.type)
	if !type_valid: type_valid = type == their.type
	if !type_valid:
		if side == Side.Input:
			assert(type_valid, "cannot connect types %s to %s" % [type,their.type])
		else: assert (type_valid, "cannot connect types %s to %s" % [their.type, type])
	
	#check if we are diffrent types since it makes no sense to connect a input to a input
	assert(side != their.side, "tried to connect two ports of the same side to eachother")

	
	return false

func _get_g3dnode_parent() -> Graph3DNode:
	var work = self
	var root = get_tree().get_root()
	while true:
		if (work == root):
			push_error("Something called _get_g3dnode_parent on a Graph3DPort that is not a descendant of a Graph3DNode")
			print_stack()
			return null
		if (work is Graph3DNode): return work
		work = work.get_parent()
	return null

class GraphConnection:
	var from: Graph3DPort
	var to: Graph3DPort
	var line: CurveMesh3D

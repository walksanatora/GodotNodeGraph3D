@tool
extends StaticBody3D
class_name Graph3DPort

## what Side of the board is this port on
enum Side {
	Input,
	Output
}

## what side of the board is this port on (this determines how it limits connections
@export var side: Graph3DPort.Side = Side.Input
## the variable type of this port (changing can result in port color changing
@export var type: Graph3DVariable = preload("res://addons/node_graph_3D/defaults/Any.tres")
## a list of one (input) or more (output) connections
var connections: Array[GraphConnection] = []

## this signal is fired from [method connect_to] [i]after[/i] the saftey checks have occured but [i]before[/i] the [GraphConnection] is made
## [br]this can be used to eg: make it so the Any ports on a graph get changed into a specific type
signal connection_started(from: Graph3DPort, to: Graph3DPort)

var _mesh: MeshInstance3D
var _collider: CollisionShape3D

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = type.display_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	set_notify_transform(true)

func connect_to(their: Graph3DPort) -> bool:
	#make it so the paths are ALWAYS created from output -> input
	if side == Side.Input: return their.connect_to(self)
	
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

	connection_started.emit(self,their)
	#region curve creation
	var line := CurveMesh3D.new()
	line.top_level = true
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.fill_to = Vector2(1, 1)
	gradient_texture.fill_from = Vector2(1,0)
	var gradient = Gradient.new()
	gradient.set_color(0, type.display_color)
	gradient.set_color(1, their.type.display_color)
	gradient_texture.gradient = gradient
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color.WHITE
	line_mat.albedo_texture = gradient_texture
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material = line_mat
	var curve3d := Curve3D.new()
	line.curve = curve3d
	var curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0,0.5))
	line.radius_profile = curve
	add_child(line)
	#endregion
	
	#make the connection
	var con = GraphConnection.make(self,their, line)
	connections.append(con)
	their.connections.append(con)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)
	their._notification(NOTIFICATION_TRANSFORM_CHANGED)
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		for con in connections:
			if side == Side.Input:
				con.line.curve.set_point_position(1, global_position - con.from.global_position)
				con.line.curve.set_point_in(1, -global_basis.x.normalized())
			else: #Side.Output
				con.line.global_position = global_position
				con.line.curve.set_point_out(0, global_basis.x.normalized())

class GraphConnection extends RefCounted:
	var from: Graph3DPort
	var to: Graph3DPort
	var line: CurveMesh3D
	static func make(from: Graph3DPort, to: Graph3DPort, line: CurveMesh3D) -> GraphConnection:
		var instance = new()
		instance.from = from
		instance.to = to
		instance.line = line
		return instance

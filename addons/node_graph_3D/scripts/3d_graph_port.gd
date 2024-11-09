@tool
extends StaticBody3D
class_name Graph3DPort

## what Side of the board is this port on
enum Side {
	Input,
	Output
}

#region exports
## what side of the board is this port on (this determines how it limits connections
@export var side: Graph3DPort.Side = Side.Input
## the variable type of this port (changing can result in port color changing
@export var type: Graph3DVariable = preload("res://addons/node_graph_3D/defaults/Any.tres"):
	set(to):
		type = to
		if !_mesh: return
		_mesh.mesh.material.albedo_color = type.display_color
## a list of one (input) or more (output) connections
@export var connections: Array[GraphConnection] = []
#endregion

var _mesh: MeshInstance3D
var _collider: CollisionShape3D

func _ready() -> void:
	_mesh = get_node_or_null("Mesh")
	if !_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = type.display_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var meshi = BoxMesh.new()
		meshi.material = mat
		var mesh = MeshInstance3D.new()
		mesh.mesh = meshi
		mesh.name = "Mesh"
		add_child(mesh)
		_mesh = mesh
	
	_collider = get_node("Collider")
	if !_collider:
		var shape = BoxShape3D.new()
		var collision = CollisionShape3D.new()
		collision.shape = shape
		collision.name = "Collider"
		add_child(collision)
		_collider = collision	
	
	scale = Vector3(0.1,0.1,0.1)
	set_notify_transform(true)
	add_to_group("bb_ignore")

func connect_to(their: Graph3DPort):
	#make it so the paths are ALWAYS created from output -> input
	if side == Side.Input: return their.connect_to(self)
	
	if !_allow_connection(their):
		assert(false, "Connection disallowed between %s and %s" % [get_path(), their.get_path()])
	
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
	
	#region connection object construction
	var con = GraphConnection.make(self,their, line)
	add_child(con)
	con.owner = owner
	connections.append(con)
	their.connections.append(con)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)
	their._notification(NOTIFICATION_TRANSFORM_CHANGED)
	#endregion
	return

func disconnect_from(them: Graph3DPort): 
	if side == Side.Input:
		push_warning("wrong side! you are supposed to call it on the output side.")
		return them.disconnect_from(self)
	for con in connections:
		print("trying_connection: %s" % con)
		if con.from == self and con.to == them:
			print("con.from and con.to match: removing")
			connections.erase(con)
			them.connections.erase(con)
			con.line.queue_free()
			con.queue_free()

func _allow_connection(to: Graph3DPort) -> bool:
	print("checking connection allowance")
	return false
	var my_parent_type = _get_parent_g3dnode_any()
	var their_parent_type = to._get_parent_g3dnode_any()
	
	var type_valid = (my_parent_type == type) or \
		(their_parent_type == to.type) or \
		(type == to.type)
	
	if !type_valid:
		push_warning("cannot connect types %s to %s" % [type,to.type])
		return false
	#check if we are diffrent types since it makes no sense to connect a input to a input
	if side == to.side: 
		push_warning("tried to connect two ports of the same side to eachother")
		return false
	if to.connections.size() > 0:
		push_warning("tried to connect to the same port mutiple times")
		return false
	return true
	
func _get_parent_g3dnode_any() -> Graph3DVariable:
	var work = self
	var root = get_tree().get_root()
	while true:
		if (work == root):
			push_error("Something called _get_g3dnode_parent on a Graph3DPort that is not a descendant of a Graph3DNode")
			print_stack()
			return null
		if (work is Graph3DNode): return work.any_type
		work = work.get_parent()
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		for con in connections:
			if !con.is_valid(): continue
			if side == Side.Input:
				con.line.curve.set_point_position(1, global_position - con.from.global_position)
				con.line.curve.set_point_in(1, -global_basis.x.normalized())
			elif side == Side.Output:
				con.line.global_position = global_position
				con.line.curve.set_point_out(0, global_basis.x.normalized())

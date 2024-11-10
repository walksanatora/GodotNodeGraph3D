@tool
@icon("res://addons/node_graph_3D/icons/Graph3D.svg")
extends Node3D
class_name Graph3DNode
## A Graph Node in 3D Space

##fired at the end of [method _recalc_appearance]
signal appearance_recalculated(this: Graph3DNode)

#region exports
@export_group("Configuration")
## A list of input variable types for this node
@export var inputs: Array[Graph3DVariable] = [
	preload("res://addons/node_graph_3D/defaults/Any.tres")
]:
	set(to):
		inputs = to
		_recalc_appearance()
## A list of output variable types for this node
@export var outputs: Array[Graph3DVariable] = [
	preload("res://addons/node_graph_3D/defaults/Any.tres")
]:
	set(to):
		outputs = to
		_recalc_appearance()

@export_group("Appearance")
## the visible name on the top of the node
@export var node_name: String = "Generic Node":
	set(to):
		node_name = to
		if !_text: return
		_text.mesh.text = to
		_recalc_appearance()
## the color of the category bar behind the node name
@export var category_color: Color = Color(0.34,0.34,0.34):
	set(to):
		category_color = to
		if !_type: return
		_type.mesh.material.albedo_color = to
## the color of the background of the node
@export var background_color: Color = Color(0.17,0.17,0.17):
	set(to):
		background_color = to
		if !_board: return
		_board.mesh.material.albedo_color = to
		
@export var text_material: StandardMaterial3D = preload("res://addons/node_graph_3D/defaults/text_material.tres"):
	set(to):
		text_material = to
		if !_text: return
		_text.mesh.material = to
		_recalc_appearance()
## how many units of padding are applied vertically
@export var vpadding: float = 0.1:
	set(to):
		vpadding = to
		_recalc_appearance()
## whats the minimum spacing betwen two variable types
@export var hpadding: float = 0.05:
	set(to):
		hpadding = to
		_recalc_appearance()

@export_group("Technical")
## the "any" variable type. meaning this type can be connected to/from any port type
@export var any_type: Graph3DVariable = preload("res://addons/node_graph_3D/defaults/Any.tres")
## The Collision mask for ports
@export_flags_3d_physics var port_phys_mask = 0
#endregion

var _text: MeshInstance3D
var _type: MeshInstance3D
var _board: MeshInstance3D
var _ports: Node

var _init = false # dummy var so that the initial setting of values wont throw errors

func _ready() -> void:
	#region text setup/validation
	var text_i = get_node_or_null("Text")
	if !(text_i is MeshInstance3D):
			if text_i: #we want *our* text to be named Text, so we remove the imposter
					text_i.free()
			var mesh = MeshInstance3D.new()
			mesh.name = "Text"
			add_child(mesh,false,INTERNAL_MODE_DISABLED)
			text_i = mesh
	var text_mesh = text_i.mesh
	if !(text_mesh is TextMesh):
			text_mesh = TextMesh.new()
			text_i.mesh = text_mesh
			text_mesh.text = node_name
	text_mesh.material = text_material
	_text = text_i
	#endregion
	#region type setup/validation
	var type_i = get_node_or_null("Type")
	if !(type_i is MeshInstance3D):
		if type_i: #we want *our* text to be named Text, so we remove the imposter
			text_i.free()
		var mesh = MeshInstance3D.new()
		mesh.name = "Type"
		add_child(mesh,false,Node.INTERNAL_MODE_DISABLED)
		type_i = mesh
	var type_mesh = type_i.mesh
	if !(type_mesh is BoxMesh):
			type_mesh = BoxMesh.new()
			type_i.mesh = type_mesh
			type_mesh.size = text_mesh.get_aabb().size * 1.1
			type_i.position = Vector3(0,0,type_mesh.size.z * -0.1)
	var type_mat = type_mesh.material
	if !(type_mat is StandardMaterial3D):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = category_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		type_mesh.material = mat
	_type = type_i
	#endregion
	#region background setup/validation
	var board_i = get_node_or_null("Board")
	if !(board_i is MeshInstance3D):
		if board_i: #we want *our* text to be named Text, so we remove the imposter
			text_i.free()
		var mesh = MeshInstance3D.new()
		mesh.name = "Board"
		add_child(mesh,false,INTERNAL_MODE_DISABLED)
		board_i = mesh
	var board_mesh = board_i.mesh
	if !(board_mesh is BoxMesh):
			board_mesh = BoxMesh.new()
			board_i.mesh = board_mesh
			board_mesh.size = text_mesh.get_aabb().size * 1.1
			board_i.position = Vector3(0,-type_mesh.size.y,board_mesh.size.z * -0.1)
	var board_mat = board_mesh.material
	if !(board_mat is StandardMaterial3D):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = background_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		board_mesh.material = mat
	_board = board_i
	#endregion
	#region ports setup/validation
	var ports_i = get_node_or_null("Ports")
	if !(ports_i is Node3D):
		if ports_i: ports_i.free()
		var child = Node3D.new()
		child.name = "Ports"
		add_child(child,false,Node.INTERNAL_MODE_DISABLED)
		ports_i = child
	_ports = ports_i
	#endregion
	_init = true
	_recalc_appearance()
	_recalc_appearance() # this is needed because for SOME REASON long variable names clip when calced only once

## Re calculates and re-ports the node based on defined variables. [br]
## All validation should have been done during setters and _ready
func _recalc_appearance():
	if !_init: return
	_board.mesh.size = Vector3.ZERO
	_type.mesh.size = Vector3.ZERO
	var count = max(inputs.size(), outputs.size())
	var child_count = _ports.get_child_count()
	var v_offset = -_text.mesh.get_aabb().size.y
	for i in max(child_count, count):
		if i >= count:
			var line = _ports.get_node("%s" % i)
			line.queue_free()
		else:
			var ret = update_or_create_line(i, v_offset)
			v_offset -= ret[1]
	
	var size = calc_aabb(self).size * Vector3(1.05,1.05,1)
	var type_size = _text.mesh.get_aabb().size.y + 0.05
	_type.mesh.size = Vector3(size.x, type_size, size.z)
	size.y -= type_size
	_board.mesh.size = size
	_board.position.y = -((size.y + type_size)/2)
	for line in _ports.get_children():
		var input: MeshInstance3D = line.get_node_or_null("Input") as MeshInstance3D
		if input:
			var x = (size.x/2) - (input.mesh.get_aabb().size.x/2) - min((hpadding/2),0.1)
			input.position.x = -x
			var port = line.get_node_or_null("Input_port")
			if !port:
				port = Graph3DPort.new()
				port.name = "Input_port"
				port.side = Graph3DPort.Side.Input
				port.collision_layer = port_phys_mask
				line.add_child(port)
				port.owner = owner
			port.type = inputs[line.name.to_int()]
			port.position.x = -max(
				input.mesh.get_aabb().size.x + (port._mesh.get_aabb().size.x * port.scale.x),
				size.x/2 + (calc_aabb(port,false).size.x/2)
			)
			
		var output: MeshInstance3D = line.get_node_or_null("Output") as MeshInstance3D
		if output:
			var x = (size.x/2) - (output.mesh.get_aabb().size.x/2) - min((hpadding/2),0.1)
			output.position.x = x
			var port = line.get_node_or_null("Output_port")
			if !port:
				port = Graph3DPort.new()
				port.name = "Output_port"
				port.side = Graph3DPort.Side.Output
				port.collision_layer = port_phys_mask
				line.add_child(port)
				port.owner = owner
			
			port.type = outputs[line.name.to_int()]
			port.position.x = max(
				output.mesh.get_aabb().size.x + (port._mesh.get_aabb().size.x * port.scale.x),
				size.x/2 + (calc_aabb(port,false).size.x/2)
			)
	appearance_recalculated.emit(self)

func update_or_create_line(i: int, y_off: float) -> Array:
	var line = _ports.get_node_or_null("%s" % i)
	var fresh = false
	if !line:
		fresh = true
		line = Node3D.new()
		line.position.y = y_off
		line.name = "%s" % i
		_ports.add_child(line)
		line.owner = owner
	#region inp/out setting
	var inp: Graph3DVariable
	if inputs.size() > i:
		inp = inputs[i]
	var out: Graph3DVariable
	if outputs.size() > i:
		out = outputs[i]
	var v_offset = 0
	#endregion
	if inp:
		var text: MeshInstance3D = line.get_node_or_null("Input")
		if !text:
			text = MeshInstance3D.new()
			var mesh := TextMesh.new()
			mesh.material = text_material
			text.name = "Input"
			text.mesh = mesh
			line.add_child(text)
		text.position.x = -((text.mesh.get_aabb().size.x/2) + (hpadding/2))
		text.mesh.text = inp.resource_name
		v_offset = text.mesh.get_aabb().size.y
	if out:
		var text: MeshInstance3D = line.get_node_or_null("Output")
		if !text:
			text = MeshInstance3D.new()
			var mesh := TextMesh.new()
			mesh.material = text_material
			text.name = "Output"
			text.mesh = mesh
			line.add_child(text)
		text.position.x = (text.mesh.get_aabb().size.x/2) + (hpadding/2)
		text.mesh.text = out.resource_name
		v_offset = max(text.mesh.get_aabb().size.y,v_offset)
	if fresh: line.position.y -= v_offset/2
	return [line, v_offset + vpadding]

## utility method to calculate a AABB for a node and all its children (should be same size and shape as the yellow box in editor)
static func calc_aabb(node: Node3D, skip_transformation: bool = true, use_global_transform: bool = false) -> AABB:
	var bounds := AABB()
	if node is VisualInstance3D:
		bounds = node.get_aabb()
	for i in range(node.get_child_count()):
		var child: Node3D = (node.get_child(i) as Node3D)
		if child and not (child.is_in_group("bb_ignore")):
			var child_bounds := calc_aabb(child,false)
			if bounds.size == Vector3.ZERO and node:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)
	if bounds.size == Vector3.ZERO and !node:
		bounds = AABB(
			Vector3(-0.2,-0.2,-0.2),
			Vector3(0.2,0.2,0.2)
		)
	if !skip_transformation:
		if use_global_transform:
			bounds = node.global_transform * bounds
		else: bounds = node.transform * bounds
	return bounds

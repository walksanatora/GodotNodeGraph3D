@icon("res://icons/Graph3D.svg")
@tool
extends Node3D
class_name Graph3DNode

@export_category("Configuration")
## A list of input variable types for this node
@export var inputs: Array[Graph3DVariable] = []:
	set(to):
		inputs = to
		_recalc_appearance()
## A list of output variable types for this node
@export var outputs: Array[Graph3DVariable] = []:
	set(to):
		outputs = to
		_recalc_appearance()

@export_category("Appearance")
## the visible name on the top of the node
@export var node_name: String = "Generic Node":
	set(to):
		node_name = to
		_text.mesh.text = to
		_recalc_appearance()
## the color of the category bar behind the node name
@export var category_color: Color = Color(0.34,0.34,0.34):
	set(to):
		_type.mesh.material.albedo_color = to
		category_color = to
## the color of the background of the node
@export var background_color: Color = Color(0.17,0.17,0.17):
	set(to):
		_board.mesh.material.albedo_color = to
		background_color = to
@export var text_material: StandardMaterial3D = preload("res://defaults/text_material.tres"):
	set(to):
		_text.mesh.material = to
		text_material = to
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

@export_category("Technical")
## the "any" variable type. meaning this type can be connected to/from any port type
@export var any_type: Graph3DVariable = preload("res://defaults/Any.tres")
## The Collision mask for ports
@export_flags_3d_physics var port_phys_mask = 0

##fired at the end of [method _recalc_appearance]
signal appearance_recalculated(this: Graph3DNode)

var _text: MeshInstance3D
var _type: MeshInstance3D
var _board: MeshInstance3D
var _ports: Node

func _ready() -> void:
	#region text setup/validation
	var text_i = get_node("Text")
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
	var type_i = get_node("Type")
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
	var board_i = get_node("Board")
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
	var ports_i = get_node("Ports")
	if !(ports_i is Node3D):
		if ports_i: ports_i.free()
		var child = Node3D.new()
		child.name = "Ports"
		add_child(child,false,Node.INTERNAL_MODE_DISABLED)
		ports_i = child
	_ports = ports_i
	#endregion
	_recalc_appearance()

## Re calculates and re-ports the node based on defined variables. [br]
## All validation should have been done during setters and _ready
func _recalc_appearance():
	_board.mesh.size = Vector3.ZERO
	_type.mesh.size = Vector3.ZERO
	for child in _ports.get_children(): child.free()
	var pos_offset = Vector3(0,-_text.mesh.get_aabb().size.y,0)
	
	for i in range(max(inputs.size(), outputs.size())):
		var line = Node3D.new()
		line.position = pos_offset
		line.name = "%s" % i
		_ports.add_child(line)
		var inp: Graph3DVariable
		if inputs.size() > i:
			inp = inputs[i]
		var out: Graph3DVariable
		if outputs.size() > i:
			out = outputs[i]
		var v_offset = 0
		if inp:
			var text := MeshInstance3D.new()
			var mesh := TextMesh.new()
			text.name = "Input"
			mesh.text = inp.resource_name
			text.mesh = mesh
			text.position.x -= (mesh.get_aabb().size.x/2) + (hpadding/2)
			line.add_child(text)
			v_offset = mesh.get_aabb().size.y
		if out:
			var text := MeshInstance3D.new()
			var mesh := TextMesh.new()
			text.name = "Output"
			mesh.text = out.resource_name
			text.mesh = mesh
			text.position.x += (mesh.get_aabb().size.x/2) + (hpadding/2)
			line.add_child(text)
			v_offset = max(mesh.get_aabb().size.y,v_offset)
		line.position.y -= v_offset/2
		pos_offset.y -= v_offset + vpadding
		pass
	
	var size = calc_aabb(self).size * Vector3(1.05,1.05,1)
	var type_size = _text.mesh.get_aabb().size.y + 0.05
	_type.mesh.size = Vector3(size.x, type_size, size.z)
	size.y -= type_size
	_board.mesh.size = size
	_board.position.y = -((size.y + type_size)/2)
	for line in _ports.get_children():
		var input: MeshInstance3D = line.get_node("Input") as MeshInstance3D
		if input:
			input.position.x = (input.mesh.get_aabb().size.x/2) - (size.x/2) + (hpadding/2)
		var output: MeshInstance3D = line.get_node("Output") as MeshInstance3D
		if output:
			output.position.x = (output.mesh.get_aabb().size.x/-2) + (size.x/2) - (hpadding/2)
	
	appearance_recalculated.emit(self)


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

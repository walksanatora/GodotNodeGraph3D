@tool
extends Node
class_name GraphConnection

@export var from: Graph3DPort
@export var to: Graph3DPort
@export var line: CurveMesh3D

static func make(from: Graph3DPort, to: Graph3DPort, line: CurveMesh3D) -> GraphConnection:
	var instance = new()
	instance.from = from
	instance.to = to
	instance.line = line
	return instance

func is_valid() -> bool:
	return from != null and to != null and line != null

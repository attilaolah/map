class_name Hexagon
extends Node

# Vertices. These are needed at construction time.
# Vertex "a" is the "top-left", others are in clockwise order.
var a: Vector3
var b: Vector3
var c: Vector3
var d: Vector3
var e: Vector3
var f: Vector3


func _init(a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3, f: Vector3) -> void:
	self.a = a
	self.b = b
	self.c = c
	self.d = d
	self.e = e
	self.f = f


func add_to(st: SurfaceTool) -> void:
	Icosahedron.add_triangle(st, a, c, e)
	Icosahedron.add_triangle(st, a, b, c)
	Icosahedron.add_triangle(st, c, d, e)
	Icosahedron.add_triangle(st, e, f, a)

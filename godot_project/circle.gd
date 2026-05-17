@tool # Bu sayede çalıştırılmasına gerek kalmadan editörde de yuvarlak görünür
extends Polygon2D

@export var yaricap: float = 100.0
@export var kose_sayisi: int = 64 # Nokta sayısı ne kadar çoksa, daire o kadar kusursuz olur

func _ready() -> void:
	create_circle_polygon()

func create_circle_polygon() -> void:
	var points = PackedVector2Array()
	
	for i in range(kose_sayisi):
		# 360 dereceyi köşe sayısına bölerek her noktanın açısını hesaplıyoruz
		var aci = i * (2.0 * PI / kose_sayisi)
		# Trigonometrik koordinat hesaplama: x = r * cos(θ), y = r * sin(θ)
		var nokta = Vector2(cos(aci), sin(aci)) * yaricap
		points.append(nokta)
		
	polygon = points

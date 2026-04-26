extends Node3D
@onready var building_3d = $maison


func _ready():
	print("===== TEST BUILDING3D =====")

	var composantes = building_3d.extraire_composantes_pour_simulation()

	print("Nombre de composantes envoyées à Flask : ", composantes.size())

	for composante in composantes:
		print(composante)

	var thermographie_test = {
		"Mur_Ch01": {
			"int": 21.0,
			"ext": 5.0
		}
	}

	building_3d.appliquer_thermographie(thermographie_test, 21.0, 5.0)

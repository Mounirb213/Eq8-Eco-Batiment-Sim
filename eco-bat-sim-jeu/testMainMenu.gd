extends Node3D

@onready var main_menu: MainMenu = $Control/ZoneGris1
@onready var building_3d: Building3D = $maison


func _ready():
	main_menu.thermographie_changee.connect(_on_thermographie_changee)

	building_3d.actualiser_liste_maillages()

	print("Test thermographie prêt.")
	print("Coche ThermoCheckButton pour activer.")
	print("Décoche ThermoCheckButton pour désactiver.")


func _on_thermographie_changee(active: bool):
	print("Thermographie active : ", active)

	if active:
		activer_thermographie_test()
	else:
		desactiver_thermographie_test()


func activer_thermographie_test():
	var thermographie_test = {}

	var temperature_interieure_test = 25.0
	var temperature_exterieure_test = -5.0

	building_3d.appliquer_thermographie(
		thermographie_test,
		temperature_interieure_test,
		temperature_exterieure_test
	)


func desactiver_thermographie_test():
	building_3d.reinitialiser_thermographie()

extends Node3D

@onready var flask_connector = $FlaskConnector


func _ready():
	flask_connector.simulation_reussie.connect(_on_simulation_reussie)
	flask_connector.erreur_simulation.connect(_on_erreur_simulation)

	var donnees_test = {
		"temperature_interieure": 21,
		"type_chauffage": "chauffage_electrique",
		"heures_chauffage_par_an": 4320,
		"date": "current",
		"composantes": [
			{
				"nom": "Mur_Test_Ext_01",
				"nom_logique": "Mur_Test",
				"surface": 10.0,
				"type_composant": "mur",
				"face": "ext",
				"isolation_type": "moyenne",
				"prise_en_compte": true
			},
			{
				"nom": "Mur_Test_Int_01",
				"nom_logique": "Mur_Test",
				"surface": 10.0,
				"type_composant": "mur",
				"face": "int",
				"isolation_type": "moyenne",
				"prise_en_compte": false
			}
		]
	}

	print("Envoi du test à Flask...")
	flask_connector.envoyer_simulation(donnees_test)


func _on_simulation_reussie(resultat):
	print("===== SIMULATION RÉUSSIE =====")
	print(resultat)

	if resultat.has("resultats_thermiques"):
		print("Pertes totales : ", resultat["resultats_thermiques"]["total"])

	if resultat.has("resultats_cout"):
		print("Coût annuel : ", resultat["resultats_cout"]["cout_annuel"])


func _on_erreur_simulation(message):
	print("===== ERREUR SIMULATION =====")
	print(message)

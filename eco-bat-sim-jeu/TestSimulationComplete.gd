extends Node3D

@onready var main_menu: MainMenu = $Control/ZoneGris1
@onready var maison_normale: Building3D = $maison
@onready var maison_coupee: Building3D = $maisonCoupee
@onready var flask_connector: FlaskConnector = $FlaskConnector
@onready var results_panel: ResultsPanel = $Control/ZoneGris2

var dernier_resultat_flask: Dictionary = {}
var simulation_en_cours: bool = false
var vue_coupee_active: bool = false


func _ready():
	print("===== TEST COMPLET GODOT + FLASK =====")

	main_menu.simulation_demandee.connect(_on_simulation_demandee)
	main_menu.thermographie_changee.connect(_on_thermographie_changee)
	main_menu.vue_coupee_changee.connect(_on_vue_coupee_changee)

	flask_connector.simulation_reussie.connect(_on_simulation_reussie)
	flask_connector.erreur_simulation.connect(_on_erreur_simulation)

	configurer_vue_initiale()

	print("Test prêt.")
	print("1. Choisis les paramètres dans l'interface.")
	print("2. Clique sur GO.")
	print("3. Coche/décoche ThermoCheckButton pour tester la thermographie.")
	print("4. Coche/décoche VueCoupeeCheckButton pour changer de modèle.")


func configurer_vue_initiale():
	vue_coupee_active = false

	maison_normale.visible = true
	maison_coupee.visible = false

	maison_normale.actualiser_liste_maillages()
	maison_coupee.actualiser_liste_maillages()


func _on_simulation_demandee(parametres: Dictionary):
	simulation_en_cours = true
	dernier_resultat_flask = {}

	print("")
	print("===== PARAMÈTRES LUS DE L'INTERFACE =====")
	print(parametres)

	# IMPORTANT :
	# On utilise toujours la maison normale pour envoyer les composantes à Flask.
	# On n'utilise jamais maisonCoupee pour le calcul.
	var composantes = maison_normale.extraire_composantes_pour_simulation()

	print("")
	print("===== COMPOSANTES EXTRAITES DE LA MAISON NORMALE =====")
	print("Nombre de composantes envoyées à Flask : ", composantes.size())

	for composante in composantes:
		composante["isolation_type"] = parametres["isolation_type"]

	if composantes.size() == 0:
		print("ERREUR : aucune composante valide trouvée.")
		simulation_en_cours = false
		return

	var donnees_pour_flask = {
		"temperature_interieure": parametres["temperature_interieure"],
		"type_chauffage": parametres["type_chauffage"],
		"heures_chauffage_par_an": parametres["heures_chauffage_par_an"],
		"date": parametres["date"],
		"composantes": composantes
	}

	print("")
	print("===== JSON ENVOYÉ À FLASK =====")
	print(donnees_pour_flask)

	flask_connector.envoyer_simulation(donnees_pour_flask)


func _on_simulation_reussie(resultat: Dictionary):
	simulation_en_cours = false

	print("")
	print("===== RÉPONSE FLASK REÇUE =====")
	print(resultat)

	dernier_resultat_flask = resultat

	afficher_resume_console(resultat)
	results_panel.afficher_resultats(resultat)

	if main_menu.lire_thermographie_active():
		appliquer_thermographie_depuis_resultat(resultat)
	else:
		reinitialiser_thermographie_sur_tous_les_modeles()


func _on_erreur_simulation(message: String):
	simulation_en_cours = false

	print("")
	print("===== ERREUR FLASK =====")
	print(message)

	results_panel.afficher_erreur(message)


func _on_thermographie_changee(active: bool):
	print("")
	print("Thermographie active : ", active)

	if not active:
		reinitialiser_thermographie_sur_tous_les_modeles()
		print("Thermographie désactivée.")
		return

	if simulation_en_cours:
		print("Simulation en cours. La thermographie sera appliquée quand Flask répondra.")
		return

	if dernier_resultat_flask.is_empty():
		print("Aucun résultat Flask disponible. Clique sur GO avant d'activer la vraie thermographie.")
		return

	appliquer_thermographie_depuis_resultat(dernier_resultat_flask)


func _on_vue_coupee_changee(active: bool):
	print("")
	print("Vue coupée active : ", active)

	vue_coupee_active = active

	if vue_coupee_active:
		maison_normale.visible = false
		maison_coupee.visible = true
	else:
		maison_normale.visible = true
		maison_coupee.visible = false

	# Si la thermographie est active, on l'applique immédiatement
	# au modèle qui vient d'être affiché.
	if main_menu.lire_thermographie_active():
		if dernier_resultat_flask.is_empty():
			print("Vue changée, mais aucun résultat Flask disponible pour la thermographie.")
			return

		appliquer_thermographie_depuis_resultat(dernier_resultat_flask)
	else:
		reinitialiser_thermographie_sur_tous_les_modeles()


func obtenir_modele_visible() -> Building3D:
	if vue_coupee_active:
		return maison_coupee

	return maison_normale


func appliquer_thermographie_depuis_resultat(resultat: Dictionary):
	var resultats_thermiques: Dictionary = {}

	if resultat.has("resultats_thermiques"):
		resultats_thermiques = resultat["resultats_thermiques"]

	elif resultat.has("thermographie"):
		resultats_thermiques = resultat

	else:
		print("Impossible d'appliquer la thermographie : resultats_thermiques absent.")
		print("Contenu reçu : ")
		print(resultat)
		return

	if not resultats_thermiques.has("thermographie"):
		print("Impossible d'appliquer la thermographie : thermographie absente.")
		print("Contenu resultats_thermiques : ")
		print(resultats_thermiques)
		return

	var thermographie = resultats_thermiques["thermographie"]

	var temperature_interieure = 21.0
	var temperature_exterieure = 0.0

	if resultat.has("conditions"):
		var conditions = resultat["conditions"]

		if conditions.has("temperature_interieure"):
			temperature_interieure = float(conditions["temperature_interieure"])

		if conditions.has("temperature_exterieure"):
			temperature_exterieure = float(conditions["temperature_exterieure"])

	var modele_visible = obtenir_modele_visible()

	modele_visible.appliquer_thermographie(
		thermographie,
		temperature_interieure,
		temperature_exterieure
	)

	print("Thermographie appliquée sur le modèle visible.")
	print("Modèle coupé actif : ", vue_coupee_active)
	print("Température intérieure : ", temperature_interieure)
	print("Température extérieure : ", temperature_exterieure)


func reinitialiser_thermographie_sur_tous_les_modeles():
	maison_normale.reinitialiser_thermographie()
	maison_coupee.reinitialiser_thermographie()


func afficher_resume_console(resultat: Dictionary):
	print("")
	print("===== RÉSUMÉ =====")

	if resultat.has("conditions"):
		var conditions = resultat["conditions"]

		if conditions.has("temperature_exterieure"):
			print("Température extérieure : ", conditions["temperature_exterieure"])

		if conditions.has("temperature_interieure"):
			print("Température intérieure : ", conditions["temperature_interieure"])

	if resultat.has("resultats_thermiques"):
		var resultats_thermiques = resultat["resultats_thermiques"]

		if resultats_thermiques.has("total"):
			print("Pertes thermiques totales : ", resultats_thermiques["total"], " W")

		if resultats_thermiques.has("murs"):
			print("Pertes murs : ", resultats_thermiques["murs"], " W")

		if resultats_thermiques.has("fenetres"):
			print("Pertes fenêtres : ", resultats_thermiques["fenetres"], " W")

		if resultats_thermiques.has("portes"):
			print("Pertes portes : ", resultats_thermiques["portes"], " W")

		if resultats_thermiques.has("toit"):
			print("Pertes toit : ", resultats_thermiques["toit"], " W")

		if resultats_thermiques.has("plafonds"):
			print("Pertes plafonds : ", resultats_thermiques["plafonds"], " W")

		if resultats_thermiques.has("sols"):
			print("Pertes sols : ", resultats_thermiques["sols"], " W")

	if resultat.has("resultats_cout"):
		var resultats_cout = resultat["resultats_cout"]

		if resultats_cout.has("consommation_energetique_kwh_an"):
			print("Consommation annuelle : ", resultats_cout["consommation_energetique_kwh_an"], " kWh/an")

		if resultats_cout.has("cout_annuel"):
			print("Coût annuel : ", resultats_cout["cout_annuel"], " $")

		if resultats_cout.has("economies_annuelles"):
			print("Économies annuelles : ", resultats_cout["economies_annuelles"], " $")

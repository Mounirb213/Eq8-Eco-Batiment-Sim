extends Node
class_name SimulationController

@export var main_menu: MainMenu
@export var flask_connector: FlaskConnector
@export var building_3d: Building3D
@export var results_panel: ResultsPanel
@export var label_statut: Label

var _derniere_reponse: Dictionary = {}


func _ready() -> void:
	if main_menu != null:
		main_menu.simulation_demandee.connect(_on_simulation_demandee)
		main_menu.thermographie_changee.connect(_on_thermographie_changee)

	if flask_connector != null:
		flask_connector.simulation_reussie.connect(_on_simulation_reussie)
		flask_connector.simulation_erreur.connect(_on_simulation_erreur)
		flask_connector.verifier_serveur()
		flask_connector.serveur_disponible.connect(_on_serveur_disponible)


func _on_simulation_demandee(parametres: Dictionary) -> void:
	if building_3d == null or flask_connector == null:
		_afficher_statut("Références Godot incomplètes.")
		return

	var isolation_type := str(parametres.get("isolation_type", "moyenne"))
	var composantes := building_3d.extraire_composantes(isolation_type)

	if composantes.is_empty():
		_afficher_statut("Aucune composante détectée dans le modèle 3D.")
		return

	var payload := {
		"temperature_interieure": parametres.get("temperature_interieure", 21.0),
		"type_chauffage": parametres.get("type_chauffage", "chauffage_electrique"),
		"heures_chauffage_par_an": parametres.get("heures_chauffage_par_an", 4320.0),
		"date": parametres.get("date", "current"),
		"composantes": composantes
	}

	_afficher_statut("Simulation en cours...")
	flask_connector.post_simulation(payload)


func _on_simulation_reussie(reponse: Dictionary) -> void:
	_derniere_reponse = reponse
	_afficher_statut(str(reponse.get("message", "Simulation terminée.")))

	if results_panel != null:
		results_panel.afficher_resultats(reponse)

	if main_menu != null and main_menu.est_thermographie_activee():
		_appliquer_thermographie_si_possible(reponse)
	else:
		if building_3d != null:
			building_3d.reinitialiser_thermographie()


func _on_simulation_erreur(message: String) -> void:
	_afficher_statut(message)


func _on_thermographie_changee(activee: bool) -> void:
	if building_3d == null:
		return

	if not activee:
		building_3d.reinitialiser_thermographie()
		return

	if _derniere_reponse.is_empty():
		_afficher_statut("Aucune thermographie disponible. Lance d'abord une simulation.")
		return

	_appliquer_thermographie_si_possible(_derniere_reponse)


func _appliquer_thermographie_si_possible(reponse: Dictionary) -> void:
	if building_3d == null:
		return

	var resultats_thermiques = reponse.get("resultats_thermiques", {})
	if typeof(resultats_thermiques) != TYPE_DICTIONARY:
		return

	var thermographie = resultats_thermiques.get("thermographie", {})
	if typeof(thermographie) != TYPE_DICTIONARY:
		return

	building_3d.appliquer_thermographie(thermographie)


func _on_serveur_disponible(ok: bool) -> void:
	if ok:
		_afficher_statut("Flask connecté.")
	else:
		_afficher_statut("Serveur Flask indisponible.")


func _afficher_statut(message: String) -> void:
	if label_statut != null:
		label_statut.text = message
	else:
		print(message)

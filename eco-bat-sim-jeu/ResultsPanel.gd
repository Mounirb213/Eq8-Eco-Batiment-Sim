extends Control
class_name ResultsPanel

@export var consommation_affichage_path: NodePath
@export var cout_affichage_path: NodePath
@export var economies_affichage_path: NodePath

var consommation_affichage: Node
var cout_affichage: Node
var economies_affichage: Node
var temp_ext_rep_label: Label


func _ready():
	recuperer_noeuds()
	afficher_valeurs_par_defaut()


func recuperer_noeuds():
	consommation_affichage = get_node_or_null(consommation_affichage_path)
	cout_affichage = get_node_or_null(cout_affichage_path)
	economies_affichage = get_node_or_null(economies_affichage_path)

	temp_ext_rep_label = find_child("TempExtRepLabel", true, false) as Label

	if temp_ext_rep_label == null:
		print("ResultsPanel : TempExtRepLabel introuvable.")


func afficher_valeurs_par_defaut():
	ecrire_dans_noeud(consommation_affichage, "0")
	ecrire_dans_noeud(cout_affichage, "0")
	ecrire_dans_noeud(economies_affichage, "0")

	if temp_ext_rep_label != null:
		temp_ext_rep_label.text = "0 °C"


func afficher_resultats(resultat_flask: Dictionary):
	if resultat_flask.is_empty():
		afficher_valeurs_par_defaut()
		return

	var consommation = lire_consommation(resultat_flask)
	var cout = lire_cout_annuel(resultat_flask)
	var economies = lire_economies(resultat_flask)
	var temperature_exterieure = lire_temperature_exterieure(resultat_flask)

	ecrire_dans_noeud(consommation_affichage, formater_nombre(consommation))
	ecrire_dans_noeud(cout_affichage, formater_nombre(cout))
	ecrire_dans_noeud(economies_affichage, formater_nombre(economies))

	if temp_ext_rep_label != null:
		temp_ext_rep_label.text = str(round(temperature_exterieure)) + " °C"


func afficher_erreur(message: String):
	ecrire_dans_noeud(consommation_affichage, "Erreur")
	ecrire_dans_noeud(cout_affichage, "-")
	ecrire_dans_noeud(economies_affichage, "-")

	if temp_ext_rep_label != null:
		temp_ext_rep_label.text = "-"


# --------------------------------------------------
# Lecture des résultats Flask
# --------------------------------------------------

func lire_consommation(resultat_flask: Dictionary) -> float:
	if not resultat_flask.has("resultats_cout"):
		return 0.0

	var resultats_cout = resultat_flask["resultats_cout"]

	if not resultats_cout.has("consommation_energetique_kwh_an"):
		return 0.0

	return float(resultats_cout["consommation_energetique_kwh_an"])


func lire_cout_annuel(resultat_flask: Dictionary) -> float:
	if not resultat_flask.has("resultats_cout"):
		return 0.0

	var resultats_cout = resultat_flask["resultats_cout"]

	if not resultats_cout.has("cout_annuel"):
		return 0.0

	return float(resultats_cout["cout_annuel"])


func lire_economies(resultat_flask: Dictionary) -> float:
	if not resultat_flask.has("resultats_cout"):
		return 0.0

	var resultats_cout = resultat_flask["resultats_cout"]

	if resultats_cout.has("economies_annuelles"):
		return float(resultats_cout["economies_annuelles"])

	return 0.0


func lire_temperature_exterieure(resultat_flask: Dictionary) -> float:
	if not resultat_flask.has("conditions"):
		return 0.0

	var conditions = resultat_flask["conditions"]

	if not conditions.has("temperature_exterieure"):
		return 0.0

	return float(conditions["temperature_exterieure"])


# --------------------------------------------------
# Écriture dans l'interface
# --------------------------------------------------

func ecrire_dans_noeud(noeud: Node, texte: String):
	if noeud == null:
		return

	if noeud is Label:
		noeud.text = texte
		return

	if noeud is LineEdit:
		noeud.text = texte
		return

	if noeud is TextEdit:
		noeud.text = texte
		return

	if noeud is Button:
		noeud.text = texte
		return


# --------------------------------------------------
# Formatage
# --------------------------------------------------

func formater_nombre(valeur: float) -> String:
	return str(arrondir(valeur, 2))


func arrondir(valeur: float, decimales: int) -> float:
	var facteur = pow(10.0, decimales)
	return round(valeur * facteur) / facteur

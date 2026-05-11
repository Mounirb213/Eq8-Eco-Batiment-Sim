extends Control
class_name ResultsPanel

# Chemins vers les labels/champs qui affichent les résultats.
# On les choisit dans l'inspecteur Godot.
@export var chemin_consommation: NodePath
@export var chemin_cout: NodePath
@export var chemin_economies: NodePath

var affichage_consommation: Node
var affichage_cout: Node
var affichage_economies: Node

var etiquette_temperature_exterieure: Label


func _ready():
	# On récupère les éléments de l'interface.
	recuperer_noeuds()

	# Au démarrage, on affiche des valeurs par défaut.
	afficher_valeurs_par_defaut()


func recuperer_noeuds():
	# Ces trois champs sont choisis dans l'inspecteur.
	affichage_consommation = get_node_or_null(chemin_consommation)
	affichage_cout = get_node_or_null(chemin_cout)
	affichage_economies = get_node_or_null(chemin_economies)

	# Ce label est trouvé automatiquement avec son nom.
	etiquette_temperature_exterieure = find_child("TempExtRepLabel", true, false) as Label


func afficher_valeurs_par_defaut():
	# Valeurs affichées avant la première simulation.
	ecrire_dans_noeud(affichage_consommation, "0")
	ecrire_dans_noeud(affichage_cout, "0")
	ecrire_dans_noeud(affichage_economies, "0")

	if etiquette_temperature_exterieure != null:
		etiquette_temperature_exterieure.text = "0 °C"


func afficher_resultats(resultat_flask: Dictionary):
	# Si Flask ne retourne rien, on remet les valeurs à zéro.
	if resultat_flask.is_empty():
		afficher_valeurs_par_defaut()
		return

	# On lit les valeurs importantes dans la réponse Flask.
	var consommation = lire_consommation(resultat_flask)
	var cout = lire_cout_annuel(resultat_flask)
	var economies = lire_economies(resultat_flask)
	var temperature_exterieure = lire_temperature_exterieure(resultat_flask)

	# On affiche les nombres dans l'interface.
	ecrire_dans_noeud(affichage_consommation, formater_nombre(consommation))
	ecrire_dans_noeud(affichage_cout, formater_nombre(cout))
	ecrire_dans_noeud(affichage_economies, formater_nombre(economies))

	# La température extérieure est affichée à l'unité avec °C.
	if etiquette_temperature_exterieure != null:
		etiquette_temperature_exterieure.text = str(round(temperature_exterieure)) + " °C"


func afficher_erreur(_message: String):
	# Si la simulation échoue, on affiche une erreur simple.
	ecrire_dans_noeud(affichage_consommation, "Erreur")
	ecrire_dans_noeud(affichage_cout, "-")
	ecrire_dans_noeud(affichage_economies, "-")

	if etiquette_temperature_exterieure != null:
		etiquette_temperature_exterieure.text = "-"


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

	if not resultats_cout.has("economies_annuelles"):
		return 0.0

	return float(resultats_cout["economies_annuelles"])


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
	# Cette fonction permet d'écrire dans différents types de nodes.
	# Comme ça, ça marche avec Label, LineEdit, TextEdit ou Button.
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
# Formatage des nombres
# --------------------------------------------------

func formater_nombre(valeur: float) -> String:
	# Les résultats principaux sont arrondis à 2 décimales.
	return str(arrondir(valeur, 2))


func arrondir(valeur: float, decimales: int) -> float:
	var facteur = pow(10.0, decimales)
	return round(valeur * facteur) / facteur

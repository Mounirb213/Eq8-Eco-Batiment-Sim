extends Node
class_name FlaskConnector

# Signal envoyé quand Flask retourne une réponse correcte.
signal simulation_reussie(resultat)

# Signal envoyé quand il y a une erreur avec Flask.
signal erreur_simulation(message)


# Adresse de la route Flask utilisée pour lancer la simulation.
@export var url_simulation: String = "http://127.0.0.1:5000/simulate"


var requete_http: HTTPRequest
var requete_en_cours: bool = false


func _ready():
	# HTTPRequest sert à envoyer une requête HTTP à Flask.
	requete_http = HTTPRequest.new()
	add_child(requete_http)

	# Quand Flask répond, Godot appelle cette fonction.
	requete_http.request_completed.connect(_on_requete_terminee)


func envoyer_simulation(donnees: Dictionary):
	"""
	Envoie les données de la simulation au backend Flask.

	Les données sont envoyées en JSON.
	"""

	# On évite d'envoyer deux simulations en même temps.
	if requete_en_cours:
		erreur_simulation.emit("Une simulation est déjà en cours.")
		return

	var corps_json = JSON.stringify(donnees)

	var entetes = [
		"Content-Type: application/json"
	]

	requete_en_cours = true

	var erreur = requete_http.request(
		url_simulation,
		entetes,
		HTTPClient.METHOD_POST,
		corps_json
	)

	# Si Godot n'arrive même pas à envoyer la requête.
	if erreur != OK:
		requete_en_cours = false
		erreur_simulation.emit("Impossible d'envoyer la requête à Flask.")


func _on_requete_terminee(resultat_requete, code_reponse, _entetes, corps):
	"""
	Fonction appelée automatiquement quand Flask répond.

	On vérifie :
	- si la requête a fonctionné
	- si Flask a répondu avec le code 200
	- si la réponse est bien du JSON
	"""

	requete_en_cours = false

	if resultat_requete != HTTPRequest.RESULT_SUCCESS:
		erreur_simulation.emit("La requête HTTP a échoué.")
		return

	if code_reponse != 200:
		var message_erreur = "Erreur du serveur Flask : " + str(code_reponse)

		var texte_erreur = corps.get_string_from_utf8()

		if texte_erreur != "":
			message_erreur += "\nRéponse : " + texte_erreur

		erreur_simulation.emit(message_erreur)
		return

	var texte_reponse = corps.get_string_from_utf8()

	var json = JSON.new()
	var erreur_json = json.parse(texte_reponse)

	if erreur_json != OK:
		erreur_simulation.emit("La réponse de Flask n'est pas un JSON valide.")
		return

	var donnees_recues = json.get_data()

	if typeof(donnees_recues) != TYPE_DICTIONARY:
		erreur_simulation.emit("La réponse de Flask n'est pas un dictionnaire.")
		return

	# Si tout est correct, on envoie le résultat aux autres scripts.
	simulation_reussie.emit(donnees_recues)

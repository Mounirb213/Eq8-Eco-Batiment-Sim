extends Node
class_name FlaskConnector

signal simulation_reussie(resultat)
signal erreur_simulation(message)

@export var url_simulation: String = "http://127.0.0.1:5000/simulate"

var http_request: HTTPRequest
var requete_en_cours: bool = false


func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(_on_request_completed)


func envoyer_simulation(donnees: Dictionary):
	if requete_en_cours:
		erreur_simulation.emit("Une simulation est déjà en cours.")
		return

	var corps_json = JSON.stringify(donnees)

	var headers = [
		"Content-Type: application/json"
	]

	requete_en_cours = true

	var erreur = http_request.request(
		url_simulation,
		headers,
		HTTPClient.METHOD_POST,
		corps_json
	)

	if erreur != OK:
		requete_en_cours = false
		erreur_simulation.emit("Impossible d'envoyer la requête à Flask.")


func _on_request_completed(result, response_code, headers, body):
	requete_en_cours = false

	if result != HTTPRequest.RESULT_SUCCESS:
		erreur_simulation.emit("La requête HTTP a échoué.")
		return

	if response_code != 200:
		var message_erreur = "Erreur du serveur Flask : " + str(response_code)

		var texte_erreur = body.get_string_from_utf8()
		if texte_erreur != "":
			message_erreur += "\nRéponse : " + texte_erreur

		erreur_simulation.emit(message_erreur)
		return

	var texte_reponse = body.get_string_from_utf8()

	var json = JSON.new()
	var erreur_parse = json.parse(texte_reponse)

	if erreur_parse != OK:
		erreur_simulation.emit("La réponse de Flask n'est pas un JSON valide.")
		return

	var resultat = json.get_data()

	if typeof(resultat) != TYPE_DICTIONARY:
		erreur_simulation.emit("La réponse de Flask n'est pas un dictionnaire.")
		return

	simulation_reussie.emit(resultat)

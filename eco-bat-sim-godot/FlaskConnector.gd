extends Node
class_name FlaskConnector

signal simulation_reussie(reponse: Dictionary)
signal simulation_erreur(message: String)
signal serveur_disponible(ok: bool)
@export var url_simulation := "http://127.0.0.1:5000/simulate"
@export var url_health := "http://127.0.0.1:5000/health"

var _http_request: HTTPRequest
var _mode_requete := ""


func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


func verifier_serveur() -> void:
	_mode_requete = "health"
	var erreur := _http_request.request(url_health)
	if erreur != OK:
		serveur_disponible.emit(false)


func post_simulation(payload: Dictionary) -> void:
	_mode_requete = "simulate"

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var body := JSON.stringify(payload)
	var erreur := _http_request.request(url_simulation, headers, HTTPClient.METHOD_POST, body)

	if erreur != OK:
		simulation_erreur.emit("Impossible d'envoyer la requête Flask. Code : %s" % erreur)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var texte := body.get_string_from_utf8()

	if _mode_requete == "health":
		serveur_disponible.emit(response_code == 200)
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		simulation_erreur.emit("La requête HTTP a échoué. Code interne : %s" % result)
		return

	if response_code < 200 or response_code >= 300:
		simulation_erreur.emit("Flask a retourné une erreur HTTP %s : %s" % [response_code, texte])
		return

	var json := JSON.new()
	var erreur_parse := json.parse(texte)
	if erreur_parse != OK:
		simulation_erreur.emit("Réponse JSON invalide côté Flask.")
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		simulation_erreur.emit("La réponse Flask n'est pas un dictionnaire JSON.")
		return

	simulation_reussie.emit(data)

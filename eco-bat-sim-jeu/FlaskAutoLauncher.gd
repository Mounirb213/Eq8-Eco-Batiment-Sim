extends Node
class_name FlaskAutoLauncher

signal serveur_pret
signal erreur_lancement(message)

@export var lancer_automatiquement: bool = true

@export var chemin_bat: String = "C:\\Users\\mouni\\Documents\\GitHub\\Eq8-Eco-Batiment-Sim\\lancer_flask.bat"
@export var url_health: String = "http://127.0.0.1:5000/health"

@export var delai_entre_tests: float = 0.5
@export var nombre_tests_max: int = 30

var health_request: HTTPRequest
var serveur_est_pret: bool = false
var serveur_lance_par_godot: bool = false


func _ready():
	health_request = HTTPRequest.new()
	add_child(health_request)

	if lancer_automatiquement:
		demarrer_serveur_si_necessaire()


func demarrer_serveur_si_necessaire():
	print("FlaskAutoLauncher : vérification du serveur Flask...")

	var deja_pret = await verifier_serveur()

	if deja_pret:
		print("FlaskAutoLauncher : serveur Flask déjà actif.")
		serveur_est_pret = true
		serveur_pret.emit()
		return

	print("FlaskAutoLauncher : serveur Flask non détecté.")
	lancer_serveur_flask()

	print("FlaskAutoLauncher : attente du serveur Flask...")

	for i in range(nombre_tests_max):
		await get_tree().create_timer(delai_entre_tests).timeout

		var pret = await verifier_serveur()

		if pret:
			print("FlaskAutoLauncher : serveur Flask prêt.")
			serveur_est_pret = true
			serveur_pret.emit()
			return

	var message = "FlaskAutoLauncher : Flask n'a pas répondu après le lancement."
	print(message)
	erreur_lancement.emit(message)


func verifier_serveur() -> bool:
	var erreur = health_request.request(url_health)

	if erreur != OK:
		return false

	var reponse = await health_request.request_completed

	var result = reponse[0]
	var response_code = reponse[1]

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		return true

	return false


func lancer_serveur_flask():
	print("FlaskAutoLauncher : lancement via fichier .bat...")

	var arguments = [
		"/C",
		"start",
		"",
		chemin_bat
	]

	var pid = OS.create_process("cmd.exe", arguments, false)

	if pid == -1:
		var message = "Impossible de lancer le fichier .bat Flask."
		print(message)
		erreur_lancement.emit(message)
		return

	serveur_lance_par_godot = true
	print("FlaskAutoLauncher : processus lancé. PID : ", pid)

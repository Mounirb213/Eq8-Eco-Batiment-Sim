extends Node3D
class_name ControleurSimulation

@onready var menu_principal: MainMenu = $Control/ZoneGris1
@onready var maison_normale: Building3D = $maison
@onready var maison_coupee: Building3D = $maisonCoupee
@onready var connecteur_flask: FlaskConnector = $FlaskConnector
@onready var panneau_resultats: ResultsPanel = $Control/ZoneGris2

var dernier_resultat_flask: Dictionary = {}
var simulation_en_cours: bool = false
var vue_coupee_active: bool = false


func _ready():
	# On connecte les signaux du menu.
	menu_principal.simulation_demandee.connect(quand_simulation_demandee)
	menu_principal.thermographie_changee.connect(quand_thermographie_changee)
	menu_principal.vue_coupee_changee.connect(quand_vue_coupee_changee)

	# On connecte les signaux du connecteur Flask.
	connecteur_flask.simulation_reussie.connect(quand_simulation_reussie)
	connecteur_flask.erreur_simulation.connect(quand_erreur_simulation)

	# Au départ, on affiche la maison normale.
	configurer_vue_initiale()


func configurer_vue_initiale():
	# La vue coupée est désactivée au début.
	vue_coupee_active = false

	maison_normale.visible = true
	maison_coupee.visible = false

	# On prépare la liste des maillages des deux modèles.
	maison_normale.actualiser_liste_maillages()
	maison_coupee.actualiser_liste_maillages()


# --------------------------------------------------
# Simulation
# --------------------------------------------------

func quand_simulation_demandee(parametres: Dictionary):
	# Cette fonction est appelée quand l'utilisateur clique sur GO.

	simulation_en_cours = true
	dernier_resultat_flask = {}

	# Important :
	# On utilise toujours la maison normale pour envoyer les composantes à Python.
	# La maison coupée sert seulement à l'affichage.
	var composantes = maison_normale.extraire_composantes_pour_simulation()

	# L'isolation choisie dans le menu est appliquée à toutes les composantes.
	for composante in composantes:
		composante["isolation_type"] = parametres["isolation_type"]

	if composantes.size() == 0:
		simulation_en_cours = false
		panneau_resultats.afficher_erreur("Aucune composante trouvée.")
		return

	var donnees_pour_flask = {
		"temperature_interieure": parametres["temperature_interieure"],
		"type_chauffage": parametres["type_chauffage"],
		"heures_chauffage_par_an": parametres["heures_chauffage_par_an"],
		"date": parametres["date"],
		"nb_occupants": parametres["nb_occupants"],
		"composantes": composantes
	}

	connecteur_flask.envoyer_simulation(donnees_pour_flask)


func quand_simulation_reussie(resultat: Dictionary):
	# Cette fonction est appelée quand Flask retourne une réponse correcte.

	simulation_en_cours = false
	dernier_resultat_flask = resultat

	# On affiche les résultats dans le panneau de droite.
	panneau_resultats.afficher_resultats(resultat)

	# Si la thermographie est cochée, on applique les couleurs.
	if menu_principal.lire_thermographie_active():
		appliquer_thermographie_depuis_resultat(resultat)
	else:
		reinitialiser_thermographie_sur_tous_les_modeles()


func quand_erreur_simulation(message: String):
	# Cette fonction est appelée si Flask retourne une erreur.

	simulation_en_cours = false
	panneau_resultats.afficher_erreur(message)


# --------------------------------------------------
# Thermographie
# --------------------------------------------------

func quand_thermographie_changee(est_active: bool):
	# Si l'utilisateur décoche la thermographie, on remet les matériaux normaux.
	if not est_active:
		reinitialiser_thermographie_sur_tous_les_modeles()
		return

	# Si la simulation est encore en cours, on attend la réponse Flask.
	if simulation_en_cours:
		return

	# Si aucune simulation n'a encore été faite, on ne peut pas appliquer la thermographie.
	if dernier_resultat_flask.is_empty():
		return

	appliquer_thermographie_depuis_resultat(dernier_resultat_flask)


func appliquer_thermographie_depuis_resultat(resultat: Dictionary):
	# La thermographie vient de resultats_thermiques dans la réponse Flask.
	if not resultat.has("resultats_thermiques"):
		return

	var resultats_thermiques = resultat["resultats_thermiques"]

	if not resultats_thermiques.has("thermographie"):
		return

	var thermographie = resultats_thermiques["thermographie"]

	var pertes_par_composant = {}

	if resultats_thermiques.has("pertes_par_composant"):
		pertes_par_composant = resultats_thermiques["pertes_par_composant"]

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
		temperature_exterieure,
		pertes_par_composant
	)


func reinitialiser_thermographie_sur_tous_les_modeles():
	# On réinitialise les deux modèles pour éviter de garder des matériaux colorés.
	maison_normale.reinitialiser_thermographie()
	maison_coupee.reinitialiser_thermographie()


# --------------------------------------------------
# Vue coupée
# --------------------------------------------------

func quand_vue_coupee_changee(est_active: bool):
	# Cette fonction change le modèle affiché.
	# La maison normale reste toujours celle utilisée pour le calcul.

	vue_coupee_active = est_active

	if vue_coupee_active:
		maison_normale.visible = false
		maison_coupee.visible = true
	else:
		maison_normale.visible = true
		maison_coupee.visible = false

	# Si la thermographie est déjà active, on l'applique directement au nouveau modèle visible.
	if menu_principal.lire_thermographie_active():
		if not dernier_resultat_flask.is_empty():
			appliquer_thermographie_depuis_resultat(dernier_resultat_flask)
	else:
		reinitialiser_thermographie_sur_tous_les_modeles()


func obtenir_modele_visible() -> Building3D:
	# Retourne le modèle actuellement visible.
	if vue_coupee_active:
		return maison_coupee

	return maison_normale

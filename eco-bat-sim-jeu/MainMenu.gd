extends Control
class_name MainMenu

# Signal envoyé quand l'utilisateur clique sur GO.
signal simulation_demandee(parametres)

# Signal envoyé quand l'utilisateur active ou désactive la thermographie.
signal thermographie_changee(active)

# Signal envoyé quand l'utilisateur active ou désactive la vue coupée.
signal vue_coupee_changee(active)


# Valeurs par défaut envoyées au backend Python.
@export var temperature_interieure_par_defaut: float = 21.0
@export var heures_chauffage_par_an: float = 4320.0


# Boutons du menu.
# Les chemins gardent les noms des nodes dans Godot.
@onready var bouton_nb_occupants: OptionButton = $NbOccupantsPanel/NbOccupantsButton
@onready var bouton_isolation: OptionButton = $IsolationPanel/IsolationButton
@onready var bouton_chauffage: OptionButton = $ChauffagePanel/ChauffageButton

# Cases pour choisir une date.
@onready var boite_jour: SpinBox = $DatePanel/DateJourBox
@onready var boite_mois: SpinBox = $DatePanel/DateMoisBox
@onready var boite_annee: SpinBox = $DatePanel/DateAnneeBox
@onready var bouton_meteo_actuelle: CheckButton = $DatePanel/DateCheckButton

# Boutons principaux.
@onready var bouton_thermographie: CheckBox = $ThermoCheckButton
@onready var bouton_vue_coupee: CheckBox = $VueCoupeeCheckButton
@onready var bouton_go: Button = $GoButton


func _ready():
	# Prépare les choix dans les menus.
	configurer_interface()

	# Connecte les boutons à leurs fonctions.
	connecter_signaux()

	# Met à jour l'état des champs de date.
	actualiser_etat_date()


func configurer_interface():
	configurer_nb_occupants()
	configurer_isolation()
	configurer_chauffage()
	configurer_date()


func connecter_signaux():
	# Quand on clique sur GO.
	bouton_go.pressed.connect(quand_bouton_go_appuye)

	# Quand on active/désactive la thermographie.
	bouton_thermographie.toggled.connect(quand_thermographie_changee)

	# Quand on active/désactive la vue coupée.
	bouton_vue_coupee.toggled.connect(quand_vue_coupee_changee)

	# Quand on active/désactive la météo actuelle.
	bouton_meteo_actuelle.toggled.connect(quand_meteo_actuelle_changee)

	# Si un paramètre change, on enlève la thermographie.
	# Ça évite de garder une ancienne couleur après une nouvelle configuration.
	bouton_nb_occupants.item_selected.connect(quand_parametre_change)
	bouton_isolation.item_selected.connect(quand_parametre_change)
	bouton_chauffage.item_selected.connect(quand_parametre_change)

	boite_jour.value_changed.connect(quand_date_changee)
	boite_mois.value_changed.connect(quand_date_changee)
	boite_annee.value_changed.connect(quand_date_changee)


# --------------------------------------------------
# Réactions aux boutons
# --------------------------------------------------

func quand_bouton_go_appuye():
	# On lit les choix de l'utilisateur.
	var parametres = lire_parametres()

	# On envoie les paramètres au contrôleur principal.
	simulation_demandee.emit(parametres)


func quand_thermographie_changee(est_active: bool):
	# Le contrôleur principal va appliquer ou enlever la thermographie.
	thermographie_changee.emit(est_active)


func quand_vue_coupee_changee(est_active: bool):
	# Le contrôleur principal va changer le modèle visible.
	vue_coupee_changee.emit(est_active)


func quand_meteo_actuelle_changee(_est_active: bool):
	# Si météo actuelle est cochée, la date entrée ne compte plus.
	actualiser_etat_date()

	# On enlève la thermographie si elle était active.
	desactiver_thermographie_si_active()


func quand_parametre_change(_index: int):
	# Appelé quand un OptionButton change.
	desactiver_thermographie_si_active()


func quand_date_changee(_valeur: float):
	# Appelé quand un SpinBox de date change.
	desactiver_thermographie_si_active()


# --------------------------------------------------
# Gestion de la thermographie
# --------------------------------------------------

func desactiver_thermographie_si_active():
	# Si l'utilisateur change un paramètre après une simulation,
	# on enlève la thermographie pour éviter un mauvais affichage.
	if bouton_thermographie.button_pressed:
		bouton_thermographie.set_pressed_no_signal(false)
		thermographie_changee.emit(false)


# --------------------------------------------------
# Gestion de la date
# --------------------------------------------------

func actualiser_etat_date():
	# Dans notre interface, ce bouton veut dire :
	# utiliser la météo actuelle.
	var meteo_actuelle_active = bouton_meteo_actuelle.button_pressed

	# Si météo actuelle est activée, on bloque les champs de date.
	boite_jour.editable = not meteo_actuelle_active
	boite_mois.editable = not meteo_actuelle_active
	boite_annee.editable = not meteo_actuelle_active


# --------------------------------------------------
# Lecture des paramètres
# --------------------------------------------------

func lire_parametres() -> Dictionary:
	# On regroupe tout ce que Python doit recevoir.
	return {
		"temperature_interieure": temperature_interieure_par_defaut,
		"type_chauffage": lire_type_chauffage(),
		"heures_chauffage_par_an": heures_chauffage_par_an,
		"date": lire_date_meteo(),
		"thermographie_active": lire_thermographie_active(),
		"isolation_type": lire_type_isolation(),
		"nb_occupants": lire_nombre_occupants(),
		"vue_coupee_active": lire_vue_coupee_active()
	}


# --------------------------------------------------
# Configuration des menus
# --------------------------------------------------

func configurer_nb_occupants():
	bouton_nb_occupants.clear()

	bouton_nb_occupants.add_item("1")
	bouton_nb_occupants.add_item("2")
	bouton_nb_occupants.add_item("3")
	bouton_nb_occupants.add_item("4")
	bouton_nb_occupants.add_item("5")

	# Valeur par défaut : 1 occupant.
	bouton_nb_occupants.select(0)


func configurer_isolation():
	bouton_isolation.clear()

	bouton_isolation.add_item("Très bonne")
	bouton_isolation.add_item("Bonne")
	bouton_isolation.add_item("Moyenne")
	bouton_isolation.add_item("Mauvaise")

	# Valeur par défaut : Moyenne.
	bouton_isolation.select(2)


func configurer_chauffage():
	bouton_chauffage.clear()

	bouton_chauffage.add_item("Électrique")
	bouton_chauffage.add_item("Gaz")
	bouton_chauffage.add_item("Thermopompe")
	bouton_chauffage.add_item("Mazout")

	# Valeur par défaut : Électrique.
	bouton_chauffage.select(0)


func configurer_date():
	boite_jour.min_value = 1
	boite_jour.max_value = 31
	boite_jour.value = 1

	boite_mois.min_value = 1
	boite_mois.max_value = 12
	boite_mois.value = 1

	boite_annee.min_value = 2016
	boite_annee.max_value = 2026
	boite_annee.value = 2024

	# Par défaut, on utilise la météo actuelle.
	bouton_meteo_actuelle.button_pressed = true


# --------------------------------------------------
# Conversion des choix pour Python
# --------------------------------------------------

func lire_nombre_occupants() -> int:
	var texte = bouton_nb_occupants.get_item_text(bouton_nb_occupants.selected)
	return int(texte)


func lire_type_isolation() -> String:
	# L'utilisateur voit des mots propres dans l'interface.
	# Python reçoit des valeurs plus simples à utiliser.
	var texte = bouton_isolation.get_item_text(bouton_isolation.selected)

	if texte == "Très bonne":
		return "tres_bonne"

	if texte == "Bonne":
		return "bonne"

	if texte == "Moyenne":
		return "moyenne"

	if texte == "Mauvaise":
		return "mauvaise"

	return "moyenne"


func lire_type_chauffage() -> String:
	# Même principe que pour l'isolation :
	# on convertit le texte du menu en valeur envoyée à Python.
	var texte = bouton_chauffage.get_item_text(bouton_chauffage.selected)

	if texte == "Électrique":
		return "chauffage_electrique"

	if texte == "Gaz":
		return "chauffage_gaz"

	if texte == "Thermopompe":
		return "thermopompe"

	if texte == "Mazout":
		return "chauffage_mazout"

	return "chauffage_electrique"


func lire_date_meteo() -> String:
	# Si météo actuelle est cochée, on envoie "current" à Python.
	if bouton_meteo_actuelle.button_pressed:
		return "current"

	var jour = int(boite_jour.value)
	var mois = int(boite_mois.value)
	var annee = int(boite_annee.value)

	# Format demandé par Python et l'API météo : AAAA-MM-JJ.
	var jour_texte = "%02d" % jour
	var mois_texte = "%02d" % mois
	var annee_texte = str(annee)

	return annee_texte + "-" + mois_texte + "-" + jour_texte


func lire_thermographie_active() -> bool:
	return bouton_thermographie.button_pressed


func lire_vue_coupee_active() -> bool:
	return bouton_vue_coupee.button_pressed

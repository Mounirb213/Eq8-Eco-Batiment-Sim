extends Control
class_name MainMenu

signal simulation_demandee(parametres)
signal thermographie_changee(active)
signal vue_coupee_changee(active)

@export var temperature_interieure_par_defaut: float = 21.0
@export var heures_chauffage_par_an: float = 4320.0

@onready var nb_occupants_button: OptionButton = $NbOccupantsPanel/NbOccupantsButton
@onready var isolation_button: OptionButton = $IsolationPanel/IsolationButton
@onready var chauffage_button: OptionButton = $ChauffagePanel/ChauffageButton

@onready var date_jour_box: SpinBox = $DatePanel/DateJourBox
@onready var date_mois_box: SpinBox = $DatePanel/DateMoisBox
@onready var date_annee_box: SpinBox = $DatePanel/DateAnneeBox
@onready var date_check_button: CheckButton = $DatePanel/DateCheckButton

@onready var thermo_check_button: CheckBox = $ThermoCheckButton
@onready var go_button: Button = $GoButton

@onready var vue_coupee_check_button: CheckBox = $VueCoupeeCheckButton


func _ready():
	configurer_interface()
	connecter_signaux()
	actualiser_etat_date()


func configurer_interface():
	configurer_nb_occupants()
	configurer_isolation()
	configurer_chauffage()
	configurer_date()


func connecter_signaux():
	go_button.pressed.connect(_on_go_button_pressed)

	thermo_check_button.toggled.connect(_on_thermo_check_button_toggled)
	date_check_button.toggled.connect(_on_date_check_button_toggled)

	nb_occupants_button.item_selected.connect(_on_parametre_modifie)
	isolation_button.item_selected.connect(_on_parametre_modifie)
	chauffage_button.item_selected.connect(_on_parametre_modifie)

	date_jour_box.value_changed.connect(_on_date_modifiee)
	date_mois_box.value_changed.connect(_on_date_modifiee)
	date_annee_box.value_changed.connect(_on_date_modifiee)
	
	vue_coupee_check_button.toggled.connect(_on_vue_coupee_check_button_toggled)


func _on_go_button_pressed():
	var parametres = lire_parametres()
	simulation_demandee.emit(parametres)


func _on_thermo_check_button_toggled(active):
	thermographie_changee.emit(active)


func _on_date_check_button_toggled(active):
	actualiser_etat_date()
	desactiver_thermographie_si_active()


func _on_parametre_modifie(index):
	desactiver_thermographie_si_active()


func _on_date_modifiee(value):
	desactiver_thermographie_si_active()
	
func _on_vue_coupee_check_button_toggled(active):
	vue_coupee_changee.emit(active)


func desactiver_thermographie_si_active():
	if thermo_check_button.button_pressed:
		thermo_check_button.set_pressed_no_signal(false)
		thermographie_changee.emit(false)


func actualiser_etat_date():
	var meteo_actuelle_active = date_check_button.button_pressed

	date_jour_box.editable = not meteo_actuelle_active
	date_mois_box.editable = not meteo_actuelle_active
	date_annee_box.editable = not meteo_actuelle_active


func lire_parametres() -> Dictionary:
	return {
		"temperature_interieure": temperature_interieure_par_defaut,
		"type_chauffage": lire_type_chauffage(),
		"heures_chauffage_par_an": heures_chauffage_par_an,
		"date": lire_date_meteo(),
		"thermographie_active": lire_thermographie_active(),
		"isolation_type": lire_isolation_type(),
		"nb_occupants": lire_nombre_occupants(),
		"vue_coupee_active": lire_vue_coupee_active()
	}


# --------------------------------------------------
# Configuration des boutons
# --------------------------------------------------

func configurer_nb_occupants():
	nb_occupants_button.clear()

	nb_occupants_button.add_item("1")
	nb_occupants_button.add_item("2")
	nb_occupants_button.add_item("3")
	nb_occupants_button.add_item("4")
	nb_occupants_button.add_item("5")

	nb_occupants_button.select(0)


func configurer_isolation():
	isolation_button.clear()

	isolation_button.add_item("Très bonne")
	isolation_button.add_item("Bonne")
	isolation_button.add_item("Moyenne")
	isolation_button.add_item("Mauvaise")

	isolation_button.select(2)


func configurer_chauffage():
	chauffage_button.clear()

	chauffage_button.add_item("Électrique")
	chauffage_button.add_item("Gaz")
	chauffage_button.add_item("Thermopompe")
	chauffage_button.add_item("Mazout")

	chauffage_button.select(0)


func configurer_date():
	date_jour_box.min_value = 1
	date_jour_box.max_value = 31
	date_jour_box.value = 1

	date_mois_box.min_value = 1
	date_mois_box.max_value = 12
	date_mois_box.value = 1

	date_annee_box.min_value = 2016
	date_annee_box.max_value = 2026
	date_annee_box.value = 2024

	date_check_button.button_pressed = true


# --------------------------------------------------
# Lecture des valeurs
# --------------------------------------------------

func lire_nombre_occupants() -> int:
	var texte = nb_occupants_button.get_item_text(nb_occupants_button.selected)
	return int(texte)


func lire_isolation_type() -> String:
	var texte = isolation_button.get_item_text(isolation_button.selected)

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
	var texte = chauffage_button.get_item_text(chauffage_button.selected)

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
	if date_check_button.button_pressed:
		return "current"

	var jour = int(date_jour_box.value)
	var mois = int(date_mois_box.value)
	var annee = int(date_annee_box.value)

	var jour_texte = "%02d" % jour
	var mois_texte = "%02d" % mois
	var annee_texte = str(annee)

	return annee_texte + "-" + mois_texte + "-" + jour_texte


func lire_thermographie_active() -> bool:
	return thermo_check_button.button_pressed

func lire_vue_coupee_active() -> bool:
	return vue_coupee_check_button.button_pressed
	
func changer_etat_go_button(actif: bool):
	go_button.disabled = not actif

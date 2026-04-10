extends Control
class_name MainMenu

signal simulation_demandee(parametres: Dictionary)
signal thermographie_changee(activee: bool)

@export var bouton_simulation: Button
@export var case_thermographie: BaseButton
@export var champ_temperature_interieure: SpinBox
@export var champ_heures_chauffage: SpinBox
@export var champ_date_meteo: LineEdit
@export var option_type_chauffage: OptionButton
@export var option_isolation: OptionButton

func _ready() -> void:
	if bouton_simulation != null:
		bouton_simulation.pressed.connect(_on_bouton_simulation_pressed)

	if case_thermographie != null:
		case_thermographie.toggled.connect(_on_case_thermographie_toggled)


func lire_parametres() -> Dictionary:
	var date_meteo := "current"
	if champ_date_meteo != null:
		date_meteo = champ_date_meteo.text.strip_edges()
		if date_meteo == "":
			date_meteo = "current"

	var temperature_interieure := 21.0
	if champ_temperature_interieure != null:
		temperature_interieure = champ_temperature_interieure.value

	var heures_chauffage_par_an := 4320.0
	if champ_heures_chauffage != null:
		heures_chauffage_par_an = champ_heures_chauffage.value

	var type_chauffage := _lire_type_chauffage()
	var isolation_type := _lire_isolation_type()

	return {
		"temperature_interieure": temperature_interieure,
		"heures_chauffage_par_an": heures_chauffage_par_an,
		"date": date_meteo,
		"type_chauffage": type_chauffage,
		"isolation_type": isolation_type,
		"thermographie_activee": est_thermographie_activee()
	}


func est_thermographie_activee() -> bool:
	if case_thermographie == null:
		return false
	return case_thermographie.button_pressed


func _lire_type_chauffage() -> String:
	if option_type_chauffage == null or option_type_chauffage.item_count == 0:
		return "chauffage_electrique"

	var index := option_type_chauffage.selected
	if index < 0:
		return "chauffage_electrique"

	var metadata = option_type_chauffage.get_item_metadata(index)
	if metadata != null and str(metadata).strip_edges() != "":
		return str(metadata)

	var texte := option_type_chauffage.get_item_text(index).strip_edges().to_lower()

	if texte == "chauffage electrique" or texte == "électrique" or texte == "electrique":
		return "chauffage_electrique"
	if texte == "chauffage gaz" or texte == "gaz":
		return "chauffage_gaz"
	if texte == "thermopompe":
		return "thermopompe"
	if texte == "chauffage mazout" or texte == "mazout":
		return "chauffage_mazout"

	return "chauffage_electrique"


func _lire_isolation_type() -> String:
	if option_isolation == null or option_isolation.item_count == 0:
		return "moyenne"

	var index := option_isolation.selected
	if index < 0:
		return "moyenne"

	var metadata = option_isolation.get_item_metadata(index)
	if metadata != null and str(metadata).strip_edges() != "":
		return str(metadata)

	var texte := option_isolation.get_item_text(index).strip_edges().to_lower()

	if texte == "mauvaise":
		return "mauvaise"
	if texte == "moyenne":
		return "moyenne"
	if texte == "bonne":
		return "bonne"
	if texte == "très bonne" or texte == "tres bonne" or texte == "très_bonne" or texte == "tres_bonne":
		return "tres_bonne"

	return "moyenne"


func _on_bouton_simulation_pressed() -> void:
	simulation_demandee.emit(lire_parametres())


func _on_case_thermographie_toggled(activee: bool) -> void:
	thermographie_changee.emit(activee)

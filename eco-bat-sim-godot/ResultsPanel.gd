extends Control
class_name ResultsPanel

@export var label_consommation: Label
@export var label_cout_annuel: Label
@export var label_economies: Label
@export var label_temperature_exterieure: Label
func afficher_resultats(reponse: Dictionary) -> void:
	if not reponse.has("resultats_cout"):
		return

	var resultats_cout: Dictionary = reponse["resultats_cout"]
	var conditions: Dictionary = reponse.get("conditions", {})

	if label_consommation != null:
		var consommation := resultats_cout.get("consommation_energetique_kwh_an", 0.0)
		label_consommation.text = "%s kWh/an" % consommation

	if label_cout_annuel != null:
		var cout_annuel := resultats_cout.get("cout_annuel", 0.0)
		label_cout_annuel.text = "%s $/an" % cout_annuel

	if label_economies != null:
		label_economies.text = "0 $/an"

	if label_temperature_exterieure != null:
		var temperature_exterieure := conditions.get("temperature_exterieure", 0.0)
		label_temperature_exterieure.text = "%s °C" % temperature_exterieure

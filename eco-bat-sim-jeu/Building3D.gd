extends Node3D
class_name Building3D

@export var isolation_par_defaut: String = "moyenne"
@export var temperature_min_couleur: float = -15.0
@export var temperature_max_couleur: float = 30.0
@export var utiliser_metadonnees: bool = true
@export var corriger_surface_automatique: bool = true
@export var seuil_surface_trop_grande: float = 20.0
@export var facteur_surface_trop_grande: float = 0.03

var noeuds_maillages: Array = []
var materiaux_originaux: Dictionary = {}

# Ce fichier a été grandement aidé par ChatGPT 
# pour les calculs de surfaces qui sont très compliqués

func _ready():
	actualiser_liste_maillages()


func actualiser_liste_maillages():
	noeuds_maillages.clear()
	collecter_maillages_recursif(self)


func collecter_maillages_recursif(noeud: Node):
	if noeud is MeshInstance3D:
		var mesh_instance = noeud as MeshInstance3D

		if mesh_instance.mesh != null:
			if not doit_ignorer_completement(mesh_instance):
				noeuds_maillages.append(mesh_instance)

	for enfant in noeud.get_children():
		collecter_maillages_recursif(enfant)


func doit_ignorer_completement(noeud: Node) -> bool:
	if utiliser_metadonnees and noeud.has_meta("ignorer_completement"):
		return bool(noeud.get_meta("ignorer_completement"))

	return false


# --------------------------------------------------
# EXTRACTION DES COMPOSANTES POUR PYTHON / FLASK
# --------------------------------------------------

func extraire_composantes_pour_simulation() -> Array:
	actualiser_liste_maillages()

	var composantes: Array = []

	for noeud in noeuds_maillages:
		if not est_noeud_valide_pour_simulation(noeud):
			continue

		var composante = construire_composante_depuis_noeud(noeud)

		if not composante.is_empty():
			composantes.append(composante)

	return composantes


func est_noeud_valide_pour_simulation(noeud: MeshInstance3D) -> bool:
	if utiliser_metadonnees:
		if noeud.has_meta("inclure_simulation"):
			return bool(noeud.get_meta("inclure_simulation"))

		if noeud.has_meta("type_composant"):
			return true

	var infos_nom = analyser_nom_composant(noeud.name)

	if infos_nom["nom_fiable"] == false:
		return false

	return true


func construire_composante_depuis_noeud(noeud: MeshInstance3D) -> Dictionary:
	var nom = str(noeud.name)

	var infos_nom = analyser_nom_composant(nom)

	var nom_logique = infos_nom["nom_logique"]
	var face = infos_nom["face"]
	var type_composant = infos_nom["type_composant"]

	if utiliser_metadonnees:
		if noeud.has_meta("nom_logique"):
			nom_logique = str(noeud.get_meta("nom_logique"))

		if noeud.has_meta("face"):
			face = str(noeud.get_meta("face")).to_lower()

		if noeud.has_meta("type_composant"):
			type_composant = str(noeud.get_meta("type_composant")).to_lower()

	var surface = calculer_surface_mesh_instance(noeud)

	if corriger_surface_automatique:
		surface = corriger_surface(surface)

	if utiliser_metadonnees and noeud.has_meta("surface"):
		surface = float(noeud.get_meta("surface"))

	var isolation_type = isolation_par_defaut

	if utiliser_metadonnees and noeud.has_meta("isolation_type"):
		isolation_type = str(noeud.get_meta("isolation_type")).to_lower()

	var prise_en_compte = false

	if face == "ext":
		prise_en_compte = true

	if utiliser_metadonnees and noeud.has_meta("prise_en_compte"):
		prise_en_compte = bool(noeud.get_meta("prise_en_compte"))

	return {
		"nom": nom,
		"nom_logique": nom_logique,
		"surface": arrondir(surface, 4),
		"type_composant": type_composant,
		"face": face,
		"isolation_type": isolation_type,
		"prise_en_compte": prise_en_compte
	}


# --------------------------------------------------
# ANALYSE DES NOMS DES MESHES
# --------------------------------------------------

func analyser_nom_composant(nom: String) -> Dictionary:
	var nom_minuscule = nom.to_lower()

	var face = "ext"

	if "_int" in nom_minuscule or nom_minuscule.ends_with("int"):
		face = "int"
	elif "_ext" in nom_minuscule or nom_minuscule.ends_with("ext"):
		face = "ext"

	var type_composant = ""
	var nom_fiable = false

	if "fenetre" in nom_minuscule or "fenêtre" in nom_minuscule or "window" in nom_minuscule:
		type_composant = "fenetre"
		nom_fiable = true

	elif "porte" in nom_minuscule or "door" in nom_minuscule:
		type_composant = "porte"
		nom_fiable = true

	elif "toit" in nom_minuscule or "roof" in nom_minuscule:
		type_composant = "toit"
		nom_fiable = true

	elif "plancher" in nom_minuscule or "sol" in nom_minuscule or "floor" in nom_minuscule:
		type_composant = "sol"
		nom_fiable = true

	elif "plafond" in nom_minuscule or "ceiling" in nom_minuscule:
		type_composant = "plafond"
		nom_fiable = true

	elif "mur" in nom_minuscule or "wall" in nom_minuscule:
		type_composant = "mur"
		nom_fiable = true

	var nom_logique = extraire_nom_logique(nom)

	return {
		"nom_logique": nom_logique,
		"face": face,
		"type_composant": type_composant,
		"nom_fiable": nom_fiable
	}


func extraire_nom_logique(nom: String) -> String:
	var parties = nom.split("_")

	if parties.size() >= 2:
		var derniere_partie = str(parties[parties.size() - 1]).to_lower()

		if derniere_partie.is_valid_int():
			if parties.size() >= 2:
				var avant_derniere = str(parties[parties.size() - 2]).to_lower()

				if avant_derniere == "int" or avant_derniere == "ext":
					parties.remove_at(parties.size() - 1)
					parties.remove_at(parties.size() - 1)

		elif derniere_partie == "int" or derniere_partie == "ext":
			parties.remove_at(parties.size() - 1)

	return joindre_parties_avec_underscore(parties)


func joindre_parties_avec_underscore(parties: Array) -> String:
	var resultat = ""

	for i in range(parties.size()):
		resultat += str(parties[i])

		if i < parties.size() - 1:
			resultat += "_"

	return resultat


# --------------------------------------------------
# CALCUL DE SURFACE
# --------------------------------------------------

func calculer_surface_mesh_instance(noeud: MeshInstance3D) -> float:
	if noeud.mesh == null:
		return 0.0

	var surface_totale = 0.0
	var mesh = noeud.mesh

	for index_surface in range(mesh.get_surface_count()):
		var tableaux = mesh.surface_get_arrays(index_surface)

		if tableaux.is_empty():
			continue

		var sommets = tableaux[Mesh.ARRAY_VERTEX]
		var indices = tableaux[Mesh.ARRAY_INDEX]

		if sommets == null:
			continue

		if sommets.is_empty():
			continue

		if indices == null or indices.is_empty():
			var i = 0

			while i + 2 < sommets.size():
				var a = noeud.global_transform * sommets[i]
				var b = noeud.global_transform * sommets[i + 1]
				var c = noeud.global_transform * sommets[i + 2]

				surface_totale += calculer_aire_triangle(a, b, c)
				i += 3

		else:
			var i = 0

			while i + 2 < indices.size():
				var a = noeud.global_transform * sommets[indices[i]]
				var b = noeud.global_transform * sommets[indices[i + 1]]
				var c = noeud.global_transform * sommets[indices[i + 2]]

				surface_totale += calculer_aire_triangle(a, b, c)
				i += 3

	return surface_totale


func calculer_aire_triangle(a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab = b - a
	var ac = c - a
	var aire = 0.5 * ab.cross(ac).length()

	return aire


# --------------------------------------------------
# THERMOGRAPHIE
# --------------------------------------------------

func appliquer_thermographie(
	thermographie: Dictionary,
	temperature_interieure_par_defaut = null,
	temperature_exterieure_par_defaut = null
):
	if noeuds_maillages.is_empty():
		actualiser_liste_maillages()

	for noeud in noeuds_maillages:
		var temperature = trouver_temperature_pour_noeud(
			noeud,
			thermographie,
			temperature_interieure_par_defaut,
			temperature_exterieure_par_defaut
		)

		if temperature == null:
			continue

		var couleur = convertir_temperature_en_couleur(float(temperature))
		appliquer_couleur_sur_noeud(noeud, couleur)


func trouver_temperature_pour_noeud(
	noeud: MeshInstance3D,
	thermographie: Dictionary,
	temperature_interieure_par_defaut = null,
	temperature_exterieure_par_defaut = null
):
	var infos_nom = analyser_nom_composant(noeud.name)

	var nom_logique = infos_nom["nom_logique"]
	var face = infos_nom["face"]

	if utiliser_metadonnees:
		if noeud.has_meta("nom_logique"):
			nom_logique = str(noeud.get_meta("nom_logique"))

		if noeud.has_meta("face"):
			face = str(noeud.get_meta("face")).to_lower()

	if thermographie.has(nom_logique):
		var donnees_composante = thermographie[nom_logique]

		if typeof(donnees_composante) == TYPE_DICTIONARY:
			if face == "int":
				return donnees_composante.get("int", temperature_interieure_par_defaut)

			if face == "ext":
				return donnees_composante.get("ext", temperature_exterieure_par_defaut)

	if face == "int":
		return temperature_interieure_par_defaut

	if face == "ext":
		return temperature_exterieure_par_defaut

	return null


func convertir_temperature_en_couleur(temperature: float) -> Color:
	var t = inverse_lerp(temperature_min_couleur, temperature_max_couleur, temperature)
	t = clamp(t, 0.0, 1.0)

	if t < 0.25:
		var progression = t / 0.25
		return Color(0.0, 0.0, 1.0).lerp(Color(0.0, 1.0, 1.0), progression)

	if t < 0.5:
		var progression = (t - 0.25) / 0.25
		return Color(0.0, 1.0, 1.0).lerp(Color(0.0, 1.0, 0.0), progression)

	if t < 0.75:
		var progression = (t - 0.5) / 0.25
		return Color(0.0, 1.0, 0.0).lerp(Color(1.0, 1.0, 0.0), progression)

	var progression = (t - 0.75) / 0.25
	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.0, 0.0), progression)


func appliquer_couleur_sur_noeud(noeud: MeshInstance3D, couleur: Color):
	if noeud.mesh == null:
		return

	enregistrer_materiaux_originaux(noeud)

	for surface_index in range(noeud.mesh.get_surface_count()):
		var materiau = noeud.get_surface_override_material(surface_index)

		if materiau == null:
			materiau = StandardMaterial3D.new()
		else:
			materiau = materiau.duplicate()

		if materiau is StandardMaterial3D:
			materiau.albedo_color = couleur
			materiau.emission_enabled = true
			materiau.emission = couleur
			materiau.emission_energy_multiplier = 0.4

		noeud.set_surface_override_material(surface_index, materiau)


func enregistrer_materiaux_originaux(noeud: MeshInstance3D):
	var cle = str(noeud.get_path())

	if materiaux_originaux.has(cle):
		return

	var liste_materiaux = []

	for surface_index in range(noeud.mesh.get_surface_count()):
		liste_materiaux.append(noeud.get_surface_override_material(surface_index))

	materiaux_originaux[cle] = liste_materiaux


func reinitialiser_thermographie():
	if noeuds_maillages.is_empty():
		actualiser_liste_maillages()

	for noeud in noeuds_maillages:
		var cle = str(noeud.get_path())

		if not materiaux_originaux.has(cle):
			continue

		var liste_materiaux = materiaux_originaux[cle]

		for surface_index in range(noeud.mesh.get_surface_count()):
			if surface_index < liste_materiaux.size():
				noeud.set_surface_override_material(surface_index, liste_materiaux[surface_index])


# --------------------------------------------------
# OUTILS
# --------------------------------------------------

func arrondir(valeur: float, nombre_decimales: int) -> float:
	var facteur = pow(10.0, nombre_decimales)
	return round(valeur * facteur) / facteur
	
func corriger_surface(surface_brute: float) -> float:
	"""
	Corrige seulement les surfaces anormalement grandes.

	Exemple :
	- une fenêtre de 2.4 m² reste 2.4 m²
	- un mur calculé à 493 m² devient environ 14.8 m²
	"""

	if surface_brute > seuil_surface_trop_grande:
		return surface_brute * facteur_surface_trop_grande

	return surface_brute

extends Node3D
class_name Building3D

# Shader utilisé pour l'effet thermographique.
# Classe aidée avec ChatGPT
const SHADER_THERMIQUE = preload("res://shaders/thermal_shader.gdshader")


# Valeurs envoyées à Python si une composante n'a pas de donnée spéciale.
@export var isolation_par_defaut: String = "moyenne"

# Échelle utilisée pour transformer une température en couleur.
@export var temperature_min_couleur: float = -15.0
@export var temperature_max_couleur: float = 25.0

# Si une composante a des métadonnées Godot, on peut les utiliser.
@export var utiliser_metadonnees: bool = true

# Correction des surfaces trop grandes.
# Certains modèles 3D ne sont pas exactement à l'échelle réelle.
@export var corriger_surface_automatique: bool = true
@export var seuil_surface_trop_grande: float = 20.0
@export var facteur_surface_trop_grande: float = 0.03

# Réglages de la thermographie.
@export var utiliser_pertes_pour_thermographie: bool = true
@export var intensite_pertes_thermographie: float = 10.0
@export var intensite_variation_thermographie: float = 0.5

# Réglages du shader thermique.
@export var utiliser_shader_thermique: bool = true
@export var force_bruit_thermique: float = 0.04
@export var force_shade_thermique: float = 0.08
@export var force_emission_thermique: float = 0.45


# Liste des MeshInstance3D trouvés dans la maison.
var noeuds_maillages: Array = []

# On garde les matériaux d'origine pour pouvoir enlever la thermographie.
var materiaux_originaux: Dictionary = {}


func _ready():
	actualiser_liste_maillages()


# --------------------------------------------------
# RÉCUPÉRATION DES MESHES DE LA MAISON
# --------------------------------------------------

func actualiser_liste_maillages():
	# On vide la liste avant de la remplir à nouveau.
	noeuds_maillages.clear()

	# On cherche tous les MeshInstance3D dans les enfants de la maison.
	collecter_maillages_recursif(self)


func collecter_maillages_recursif(noeud: Node):
	# Si le node est un mesh 3D, on peut l'ajouter à la liste.
	if noeud is MeshInstance3D:
		var maillage = noeud as MeshInstance3D

		if maillage.mesh != null:
			if not doit_ignorer_completement(maillage):
				noeuds_maillages.append(maillage)

	# On répète la recherche dans les enfants.
	for enfant in noeud.get_children():
		collecter_maillages_recursif(enfant)


func doit_ignorer_completement(noeud: Node) -> bool:
	# Si un mesh a la métadonnée "ignorer_completement",
	# il ne sera pas utilisé dans la simulation ni dans la thermographie.
	if utiliser_metadonnees and noeud.has_meta("ignorer_completement"):
		return bool(noeud.get_meta("ignorer_completement"))

	return false


# --------------------------------------------------
# EXTRACTION DES COMPOSANTES POUR PYTHON / FLASK
# --------------------------------------------------

func extraire_composantes_pour_simulation() -> Array:
	# On met la liste à jour avant d'extraire les composantes.
	actualiser_liste_maillages()

	var composantes: Array = []

	for maillage in noeuds_maillages:
		if not est_maillage_valide_pour_simulation(maillage):
			continue

		var composante = construire_composante_depuis_maillage(maillage)

		if not composante.is_empty():
			composantes.append(composante)

	return composantes


func est_maillage_valide_pour_simulation(maillage: MeshInstance3D) -> bool:
	# Si une métadonnée dit clairement de l'inclure ou non, on la respecte.
	if utiliser_metadonnees:
		if maillage.has_meta("inclure_simulation"):
			return bool(maillage.get_meta("inclure_simulation"))

		if maillage.has_meta("type_composant"):
			return true

	# Sinon, on regarde le nom du mesh.
	var infos_nom = analyser_nom_composant(maillage.name)

	if infos_nom["nom_fiable"] == false:
		return false

	return true


func construire_composante_depuis_maillage(maillage: MeshInstance3D) -> Dictionary:
	var nom = str(maillage.name)

	var infos_nom = analyser_nom_composant(nom)

	var nom_logique = infos_nom["nom_logique"]
	var face = infos_nom["face"]
	var type_composant = infos_nom["type_composant"]

	# Les métadonnées sont prioritaires si elles existent.
	if utiliser_metadonnees:
		if maillage.has_meta("nom_logique"):
			nom_logique = str(maillage.get_meta("nom_logique"))

		if maillage.has_meta("face"):
			face = str(maillage.get_meta("face")).to_lower()

		if maillage.has_meta("type_composant"):
			type_composant = str(maillage.get_meta("type_composant")).to_lower()

	var surface = calculer_surface_maillage(maillage)

	if corriger_surface_automatique:
		surface = corriger_surface(surface)

	if utiliser_metadonnees and maillage.has_meta("surface"):
		surface = float(maillage.get_meta("surface"))

	var isolation_type = isolation_par_defaut

	if utiliser_metadonnees and maillage.has_meta("isolation_type"):
		isolation_type = str(maillage.get_meta("isolation_type")).to_lower()

	# Par défaut, une face extérieure compte pour le calcul énergétique.
	var prise_en_compte = false

	if face == "ext":
		prise_en_compte = true

	if utiliser_metadonnees and maillage.has_meta("prise_en_compte"):
		prise_en_compte = bool(maillage.get_meta("prise_en_compte"))

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
# ANALYSE DU NOM DES MESHES
# --------------------------------------------------

func analyser_nom_composant(nom: String) -> Dictionary:
	# Exemple de nom :
	# Mur_Ch01_Ext_01
	# Mur_Ch01_Int_01
	# Fenetre_Ch01_03
	var nom_minuscule = nom.to_lower()

	var face = "ext"

	if "_int" in nom_minuscule or nom_minuscule.ends_with("int"):
		face = "int"
	elif "_ext" in nom_minuscule or nom_minuscule.ends_with("ext"):
		face = "ext"

	var type_composant = ""
	var nom_fiable = false

	if "fenetre" in nom_minuscule:
		type_composant = "fenetre"
		nom_fiable = true

	elif "porte" in nom_minuscule:
		type_composant = "porte"
		nom_fiable = true

	elif "toit" in nom_minuscule:
		type_composant = "toit"
		nom_fiable = true

	elif "sol" in nom_minuscule or "plancher" in nom_minuscule:
		type_composant = "sol"
		nom_fiable = true

	elif "plafond" in nom_minuscule:
		type_composant = "plafond"
		nom_fiable = true

	elif "mur" in nom_minuscule:
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
	# Le nom logique sert à regrouper les faces intérieures et extérieures.
	# Exemple :
	# Mur_Ch01_Ext_01 devient Mur_Ch01
	var parties = nom.split("_")

	if parties.size() >= 2:
		var derniere_partie = str(parties[parties.size() - 1]).to_lower()

		if derniere_partie.is_valid_int():
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

func calculer_surface_maillage(maillage: MeshInstance3D) -> float:
	# Cette partie est plus avancée.
	# Elle calcule la surface en additionnant les triangles du mesh.
	# Aidé avec ChatGPT

	if maillage.mesh == null:
		return 0.0

	var surface_totale = 0.0
	var mesh = maillage.mesh

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

		# Cas 1 : le mesh n'a pas d'indices.
		if indices == null or indices.is_empty():
			var i = 0

			while i + 2 < sommets.size():
				var point_a = maillage.global_transform * sommets[i]
				var point_b = maillage.global_transform * sommets[i + 1]
				var point_c = maillage.global_transform * sommets[i + 2]

				surface_totale += calculer_aire_triangle(point_a, point_b, point_c)

				i += 3

		# Cas 2 : le mesh utilise des indices.
		else:
			var i = 0

			while i + 2 < indices.size():
				var point_a = maillage.global_transform * sommets[indices[i]]
				var point_b = maillage.global_transform * sommets[indices[i + 1]]
				var point_c = maillage.global_transform * sommets[indices[i + 2]]

				surface_totale += calculer_aire_triangle(point_a, point_b, point_c)

				i += 3

	return surface_totale


func calculer_aire_triangle(point_a: Vector3, point_b: Vector3, point_c: Vector3) -> float:
	# Aire d'un triangle en 3D.
	# Aidé avec ChatGPT
	var cote_ab = point_b - point_a
	var cote_ac = point_c - point_a

	var aire = 0.5 * cote_ab.cross(cote_ac).length()

	return aire


# --------------------------------------------------
# THERMOGRAPHIE
# --------------------------------------------------

func appliquer_thermographie(
	thermographie: Dictionary,
	temperature_interieure_par_defaut = null,
	temperature_exterieure_par_defaut = null,
	pertes_par_composant: Dictionary = {}
):
	if noeuds_maillages.is_empty():
		actualiser_liste_maillages()

	var perte_max = trouver_perte_max(pertes_par_composant)

	for maillage in noeuds_maillages:
		var temperature_base = trouver_temperature_pour_maillage(
			maillage,
			thermographie,
			temperature_interieure_par_defaut,
			temperature_exterieure_par_defaut
		)

		if temperature_base == null:
			continue

		var temperature_visuelle = calculer_temperature_visuelle(
			maillage,
			float(temperature_base),
			pertes_par_composant,
			perte_max
		)

		if utiliser_shader_thermique:
			appliquer_shader_thermique_sur_maillage(maillage, temperature_visuelle)
		else:
			var couleur = convertir_temperature_en_couleur(temperature_visuelle)
			couleur = ajouter_ombrage_sur_couleur(maillage, couleur)
			appliquer_couleur_sur_maillage(maillage, couleur)


func trouver_temperature_pour_maillage(
	maillage: MeshInstance3D,
	thermographie: Dictionary,
	temperature_interieure_par_defaut = null,
	temperature_exterieure_par_defaut = null
):
	var infos_nom = analyser_nom_composant(maillage.name)

	var nom_logique = infos_nom["nom_logique"]
	var face = infos_nom["face"]

	if utiliser_metadonnees:
		if maillage.has_meta("nom_logique"):
			nom_logique = str(maillage.get_meta("nom_logique"))

		if maillage.has_meta("face"):
			face = str(maillage.get_meta("face")).to_lower()

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


func trouver_perte_max(pertes_par_composant: Dictionary) -> float:
	var perte_max = 0.0

	for nom_composant in pertes_par_composant.keys():
		var perte = float(pertes_par_composant[nom_composant])

		if perte > perte_max:
			perte_max = perte

	return perte_max


func calculer_temperature_visuelle(
	maillage: MeshInstance3D,
	temperature_base: float,
	pertes_par_composant: Dictionary,
	perte_max: float
) -> float:
	var infos_nom = analyser_nom_composant(maillage.name)

	var face = infos_nom["face"]
	var type_composant = infos_nom["type_composant"]

	if utiliser_metadonnees and maillage.has_meta("face"):
		face = str(maillage.get_meta("face")).to_lower()

	if utiliser_metadonnees and maillage.has_meta("type_composant"):
		type_composant = str(maillage.get_meta("type_composant")).to_lower()

	var perte_maillage = obtenir_perte_du_maillage(maillage, pertes_par_composant)
	var ratio_perte = 0.0

	if perte_max > 0:
		ratio_perte = perte_maillage / perte_max
		ratio_perte = clamp(ratio_perte, 0.0, 1.0)

	var temperature_visuelle = temperature_base

	if face == "ext":
		# On refroidit un peu l'extérieur pour éviter que tout devienne jaune.
		temperature_visuelle = temperature_base - 6.0

		# Plus une composante perd de chaleur, plus elle devient chaude visuellement.
		temperature_visuelle += ratio_perte * intensite_pertes_thermographie

	elif face == "int":
		# L'intérieur est chaud, mais on évite qu'il devienne rouge partout.
		temperature_visuelle = temperature_base - 2.0
		temperature_visuelle += ratio_perte * 3.0

	# Petits ajustements pour rendre le résultat plus agréable.
	if type_composant == "toit":
		temperature_visuelle -= 2.0

	if type_composant == "sol":
		temperature_visuelle -= 3.0

	if type_composant == "fenetre":
		temperature_visuelle += ratio_perte * 2.0

	if type_composant == "porte":
		temperature_visuelle += ratio_perte * 1.5

	var variation = calculer_variation_selon_nom(maillage.name)
	temperature_visuelle += variation * intensite_variation_thermographie

	return temperature_visuelle


func obtenir_perte_du_maillage(maillage: MeshInstance3D, pertes_par_composant: Dictionary) -> float:
	var nom_maillage = str(maillage.name)

	if pertes_par_composant.has(nom_maillage):
		return float(pertes_par_composant[nom_maillage])

	return 0.0


func calculer_variation_selon_nom(nom: String) -> float:
	# Donne une petite variation stable selon le nom du mesh.
	# Ça évite que tous les murs aient exactement la même couleur.
	# Aidé avec ChatGPT
	var total = 0

	for i in range(nom.length()):
		total += nom.unicode_at(i) * (i + 1)

	var valeur = float(total % 1000) / 1000.0

	return valeur * 2.0 - 1.0


func ajouter_ombrage_sur_couleur(maillage: MeshInstance3D, couleur: Color) -> Color:
	var variation = calculer_variation_selon_nom(maillage.name)

	if variation > 0:
		return couleur.lerp(Color(1.0, 1.0, 1.0), variation * 0.12)

	return couleur.lerp(Color(0.0, 0.0, 0.0), abs(variation) * 0.12)


func convertir_temperature_en_couleur(temperature: float) -> Color:
	# Convertit une température en couleur.
	# Bleu = froid, rouge = chaud.
	var position = inverse_lerp(temperature_min_couleur, temperature_max_couleur, temperature)
	position = clamp(position, 0.0, 1.0)

	if position < 0.25:
		var progression = position / 0.25
		return Color(0.0, 0.0, 1.0).lerp(Color(0.0, 1.0, 1.0), progression)

	if position < 0.5:
		var progression = (position - 0.25) / 0.25
		return Color(0.0, 1.0, 1.0).lerp(Color(0.0, 1.0, 0.0), progression)

	if position < 0.75:
		var progression = (position - 0.5) / 0.25
		return Color(0.0, 1.0, 0.0).lerp(Color(1.0, 1.0, 0.0), progression)

	var progression = (position - 0.75) / 0.25

	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.0, 0.0), progression)


func appliquer_couleur_sur_maillage(maillage: MeshInstance3D, couleur: Color):
	if maillage.mesh == null:
		return

	enregistrer_materiaux_originaux(maillage)

	for index_surface in range(maillage.mesh.get_surface_count()):
		var materiau = maillage.get_surface_override_material(index_surface)

		if materiau == null:
			materiau = StandardMaterial3D.new()
		else:
			materiau = materiau.duplicate()

		if materiau is StandardMaterial3D:
			materiau.albedo_color = couleur
			materiau.emission_enabled = true
			materiau.emission = couleur
			materiau.emission_energy_multiplier = 0.4
			materiau.cull_mode = BaseMaterial3D.CULL_DISABLED

		maillage.set_surface_override_material(index_surface, materiau)


func appliquer_shader_thermique_sur_maillage(maillage: MeshInstance3D, temperature_visuelle: float):
	if maillage.mesh == null:
		return

	enregistrer_materiaux_originaux(maillage)

	var ratio_temperature = inverse_lerp(
		temperature_min_couleur,
		temperature_max_couleur,
		temperature_visuelle
	)

	ratio_temperature = clamp(ratio_temperature, 0.0, 1.0)

	for index_surface in range(maillage.mesh.get_surface_count()):
		var materiau = ShaderMaterial.new()

		materiau.shader = SHADER_THERMIQUE

		materiau.set_shader_parameter("temperature_ratio", ratio_temperature)
		materiau.set_shader_parameter("noise_strength", force_bruit_thermique)
		materiau.set_shader_parameter("shade_strength", force_shade_thermique)
		materiau.set_shader_parameter("emission_strength", force_emission_thermique)

		maillage.set_surface_override_material(index_surface, materiau)


func enregistrer_materiaux_originaux(maillage: MeshInstance3D):
	var cle = str(maillage.get_path())

	if materiaux_originaux.has(cle):
		return

	var liste_materiaux = []

	for index_surface in range(maillage.mesh.get_surface_count()):
		liste_materiaux.append(maillage.get_surface_override_material(index_surface))

	materiaux_originaux[cle] = liste_materiaux


func reinitialiser_thermographie():
	if noeuds_maillages.is_empty():
		actualiser_liste_maillages()

	for maillage in noeuds_maillages:
		var cle = str(maillage.get_path())

		if not materiaux_originaux.has(cle):
			continue

		var liste_materiaux = materiaux_originaux[cle]

		for index_surface in range(maillage.mesh.get_surface_count()):
			if index_surface < liste_materiaux.size():
				maillage.set_surface_override_material(index_surface, liste_materiaux[index_surface])


# --------------------------------------------------
# OUTILS
# --------------------------------------------------

func arrondir(valeur: float, nombre_decimales: int) -> float:
	var facteur = pow(10.0, nombre_decimales)
	return round(valeur * facteur) / facteur


func corriger_surface(surface_brute: float) -> float:
	# Si une surface est beaucoup trop grande, on la réduit.
	# Ça corrige les problèmes d'échelle du modèle 3D.
	if surface_brute > seuil_surface_trop_grande:
		return surface_brute * facteur_surface_trop_grande

	return surface_brute

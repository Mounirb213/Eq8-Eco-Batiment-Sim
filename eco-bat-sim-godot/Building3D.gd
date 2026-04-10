extends Node3D
class_name Building3D

@export var racine_modele: Node3D
@export var temperature_min := -20.0
@export var temperature_max := 30.0

var _meshes_batiment: Array[MeshInstance3D] = []
var _materiaux_originaux := {}
var _derniere_thermographie: Dictionary = {}


func _ready() -> void:
	reconstruire_cache_meshes()


func reconstruire_cache_meshes() -> void:
	_meshes_batiment.clear()
	var racine: Node = racine_modele if racine_modele != null else self
	_collecter_meshes(racine)


func extraire_composantes(isolation_globale: String) -> Array:
	if _meshes_batiment.is_empty():
		reconstruire_cache_meshes()

	var composantes: Array = []

	for mesh_instance in _meshes_batiment:
		if not _est_composante_batiment(mesh_instance):
			continue

		var type_composant := _determiner_type_composant(mesh_instance)
		if type_composant == "":
			continue

		var face := _determiner_face(mesh_instance)
		var composante := {
			"nom": mesh_instance.name,
			"nom_logique": _determiner_nom_logique(mesh_instance),
			"surface": round(_calculer_surface_mesh(mesh_instance) * 10000.0) / 10000.0,
			"type_composant": type_composant,
			"face": face,
			"isolation_type": _determiner_isolation(mesh_instance, isolation_globale),
			"prise_en_compte": _determiner_prise_en_compte(mesh_instance, face)
		}
		composantes.append(composante)

	return composantes


func appliquer_thermographie(thermographie: Dictionary) -> void:
	_derniere_thermographie = thermographie

	if _meshes_batiment.is_empty():
		reconstruire_cache_meshes()

	for mesh_instance in _meshes_batiment:
		if mesh_instance.mesh == null:
			continue

		var nom_logique := _determiner_nom_logique(mesh_instance)
		var face := _determiner_face(mesh_instance)

		if not thermographie.has(nom_logique):
			continue

		var donnees = thermographie[nom_logique]
		if typeof(donnees) != TYPE_DICTIONARY:
			continue

		if not donnees.has(face):
			continue

		var temperature = donnees[face]
		if temperature == null:
			continue

		_appliquer_couleur_temperature(mesh_instance, float(temperature))


func reinitialiser_thermographie() -> void:
	for mesh_instance in _meshes_batiment:
		_restaurer_materiaux_originaux(mesh_instance)


func reappliquer_derniere_thermographie() -> void:
	if _derniere_thermographie.is_empty():
		return
	appliquer_thermographie(_derniere_thermographie)


func _collecter_meshes(noeud: Node) -> void:
	for enfant in noeud.get_children():
		if enfant is MeshInstance3D:
			_meshes_batiment.append(enfant)
		_collecter_meshes(enfant)


func _est_composante_batiment(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance.mesh == null:
		return false

	if mesh_instance.has_meta("ignorer_simulation") and bool(mesh_instance.get_meta("ignorer_simulation")):
		return false

	if mesh_instance.has_meta("type_composant"):
		return true

	return _determiner_type_composant(mesh_instance) != ""


func _determiner_type_composant(mesh_instance: MeshInstance3D) -> String:
	if mesh_instance.has_meta("type_composant"):
		return str(mesh_instance.get_meta("type_composant")).strip_edges().to_lower()

	var nom := mesh_instance.name.strip_edges().to_lower()

	if nom.begins_with("mur"):
		return "mur"
	if nom.begins_with("fenetre") or nom.begins_with("fenêtre"):
		return "fenetre"
	if nom.begins_with("porte"):
		return "porte"
	if nom.begins_with("toit"):
		return "toit"
	if nom.begins_with("plancher") or nom.begins_with("sol"):
		return "sol"
	if nom.begins_with("plafond"):
		return "plafond"

	return ""


func _determiner_face(mesh_instance: MeshInstance3D) -> String:
	if mesh_instance.has_meta("face"):
		return str(mesh_instance.get_meta("face")).strip_edges().to_lower()

	var nom := mesh_instance.name.strip_edges().to_lower()

	if "_int_" in nom or nom.ends_with("_int"):
		return "int"
	if "_ext_" in nom or nom.ends_with("_ext"):
		return "ext"

	return "ext"


func _determiner_nom_logique(mesh_instance: MeshInstance3D) -> String:
	if mesh_instance.has_meta("nom_logique"):
		return str(mesh_instance.get_meta("nom_logique")).strip_edges()

	var nom := mesh_instance.name.strip_edges()
	var suffixes := [
		"_Int_01", "_Ext_01",
		"_Int_02", "_Ext_02",
		"_Int", "_Ext",
		"_int_01", "_ext_01",
		"_int_02", "_ext_02",
		"_int", "_ext"
	]

	for suffixe in suffixes:
		if nom.ends_with(suffixe):
			return nom.substr(0, nom.length() - suffixe.length())

	var morceaux_int := nom.split("_Int_")
	if morceaux_int.size() > 1:
		return morceaux_int[0]

	var morceaux_ext := nom.split("_Ext_")
	if morceaux_ext.size() > 1:
		return morceaux_ext[0]

	return nom


func _determiner_isolation(mesh_instance: MeshInstance3D, isolation_globale: String) -> String:
	if mesh_instance.has_meta("isolation_type"):
		return str(mesh_instance.get_meta("isolation_type")).strip_edges().to_lower()
	return isolation_globale


func _determiner_prise_en_compte(mesh_instance: MeshInstance3D, face: String) -> bool:
	if mesh_instance.has_meta("prise_en_compte"):
		return bool(mesh_instance.get_meta("prise_en_compte"))
	return face == "ext"


func _calculer_surface_mesh(mesh_instance: MeshInstance3D) -> float:
	if mesh_instance.mesh == null:
		return 0.0

	var surface_totale := 0.0
	var mesh := mesh_instance.mesh

	for surface_index in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

		if vertices.is_empty():
			continue

		if not indices.is_empty():
			for i in range(0, indices.size(), 3):
				if i + 2 >= indices.size():
					break
				surface_totale += _aire_triangle(
					mesh_instance,
					vertices[indices[i]],
					vertices[indices[i + 1]],
					vertices[indices[i + 2]]
				)
		else:
			for i in range(0, vertices.size(), 3):
				if i + 2 >= vertices.size():
					break
				surface_totale += _aire_triangle(
					mesh_instance,
					vertices[i],
					vertices[i + 1],
					vertices[i + 2]
				)

	return surface_totale


func _aire_triangle(mesh_instance: MeshInstance3D, a: Vector3, b: Vector3, c: Vector3) -> float:
	var p1 := mesh_instance.to_global(a)
	var p2 := mesh_instance.to_global(b)
	var p3 := mesh_instance.to_global(c)
	return ((p2 - p1).cross(p3 - p1)).length() * 0.5


func _appliquer_couleur_temperature(mesh_instance: MeshInstance3D, temperature: float) -> void:
	_sauvegarder_materiaux_originaux(mesh_instance)

	var couleur := _couleur_pour_temperature(temperature)
	var mesh := mesh_instance.mesh

	for surface_index in range(mesh.get_surface_count()):
		var material := StandardMaterial3D.new()
		material.albedo_color = couleur
		material.emission_enabled = true
		material.emission = couleur
		material.roughness = 1.0
		mesh_instance.set_surface_override_material(surface_index, material)


func _sauvegarder_materiaux_originaux(mesh_instance: MeshInstance3D) -> void:
	var cle := str(mesh_instance.get_path())
	if _materiaux_originaux.has(cle):
		return

	var originaux: Array = []
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		originaux.append(mesh_instance.get_surface_override_material(surface_index))

	_materiaux_originaux[cle] = originaux


func _restaurer_materiaux_originaux(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return

	var cle := str(mesh_instance.get_path())
	if not _materiaux_originaux.has(cle):
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			mesh_instance.set_surface_override_material(surface_index, null)
		return

	var originaux: Array = _materiaux_originaux[cle]
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material = null
		if surface_index < originaux.size():
			material = originaux[surface_index]
		mesh_instance.set_surface_override_material(surface_index, material)


func _couleur_pour_temperature(temperature: float) -> Color:
	var t := inverse_lerp(temperature_min, temperature_max, temperature)
	t = clamp(t, 0.0, 1.0)

	if t < 0.25:
		return Color(0.0, lerp(0.0, 1.0, t / 0.25), 1.0)
	elif t < 0.5:
		return Color(0.0, 1.0, lerp(1.0, 0.0, (t - 0.25) / 0.25))
	elif t < 0.75:
		return Color(lerp(0.0, 1.0, (t - 0.5) / 0.25), 1.0, 0.0)
	else:
		return Color(1.0, lerp(1.0, 0.0, (t - 0.75) / 0.25), 0.0)

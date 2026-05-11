shader_type spatial;
render_mode unshaded, cull_disabled;

// Ce shader sert à donner un effet de thermographie.
// Les couleurs changent selon la température envoyée par Building3D.gd.
// Aidé avec ChatGPT

uniform float temperature_ratio : hint_range(0.0, 1.0) = 0.5;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.12;
uniform float shade_strength : hint_range(0.0, 0.5) = 0.18;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.65;

// Position du pixel dans le monde 3D.
// On l'utilise pour créer de petites variations sur la couleur.
varying vec3 position_monde;


// Fonction utilisée pour générer une valeur pseudo-aléatoire.
// Ça sert au bruit visuel de la thermographie.
float generer_valeur(vec3 position) {
	position = fract(position * 0.3183099 + vec3(0.1, 0.2, 0.3));
	position *= 17.0;

	return fract(position.x * position.y * position.z * (position.x + position.y + position.z));
}


// Crée un bruit doux à partir de la position dans le monde.
// Ce n'est pas du vrai hasard, mais ça donne un effet moins uniforme.
float bruit(vec3 position) {
	vec3 base = floor(position);
	vec3 reste = fract(position);

	reste = reste * reste * (3.0 - 2.0 * reste);

	float v000 = generer_valeur(base + vec3(0.0, 0.0, 0.0));
	float v100 = generer_valeur(base + vec3(1.0, 0.0, 0.0));
	float v010 = generer_valeur(base + vec3(0.0, 1.0, 0.0));
	float v110 = generer_valeur(base + vec3(1.0, 1.0, 0.0));
	float v001 = generer_valeur(base + vec3(0.0, 0.0, 1.0));
	float v101 = generer_valeur(base + vec3(1.0, 0.0, 1.0));
	float v011 = generer_valeur(base + vec3(0.0, 1.0, 1.0));
	float v111 = generer_valeur(base + vec3(1.0, 1.0, 1.0));

	float x00 = mix(v000, v100, reste.x);
	float x10 = mix(v010, v110, reste.x);
	float x01 = mix(v001, v101, reste.x);
	float x11 = mix(v011, v111, reste.x);

	float xy0 = mix(x00, x10, reste.y);
	float xy1 = mix(x01, x11, reste.y);

	return mix(xy0, xy1, reste.z);
}


// Convertit une valeur entre 0 et 1 en couleur thermique.
// 0 = froid, 1 = chaud.
vec3 couleur_thermique(float valeur) {
	valeur = clamp(valeur, 0.0, 1.0);

	vec3 violet = vec3(0.25, 0.0, 0.85);
	vec3 bleu = vec3(0.0, 0.1, 1.0);
	vec3 cyan = vec3(0.0, 0.9, 1.0);
	vec3 vert = vec3(0.0, 1.0, 0.1);
	vec3 jaune = vec3(1.0, 1.0, 0.0);
	vec3 orange = vec3(1.0, 0.45, 0.0);
	vec3 rouge = vec3(1.0, 0.0, 0.0);

	if (valeur < 0.16) {
		return mix(violet, bleu, valeur / 0.16);
	}

	if (valeur < 0.32) {
		return mix(bleu, cyan, (valeur - 0.16) / 0.16);
	}

	if (valeur < 0.48) {
		return mix(cyan, vert, (valeur - 0.32) / 0.16);
	}

	if (valeur < 0.64) {
		return mix(vert, jaune, (valeur - 0.48) / 0.16);
	}

	if (valeur < 0.82) {
		return mix(jaune, orange, (valeur - 0.64) / 0.18);
	}

	return mix(orange, rouge, (valeur - 0.82) / 0.18);
}


// Fonction appelée pour chaque sommet du mesh.
void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


// Fonction appelée pour chaque pixel visible.
void fragment() {
	// Bruit large : donne un dégradé doux.
	float bruit_large = bruit(position_monde * 0.55);

	// Bruit moyen : ajoute un peu de variation.
	float bruit_moyen = bruit(position_monde * 1.25);

	// Petit bruit : ajoute un léger détail.
	float petit_bruit = bruit(position_monde * 2.5);

	float variation = 0.0;

	variation += (bruit_large - 0.5) * noise_strength;
	variation += (bruit_moyen - 0.5) * noise_strength * 0.35;
	variation += (petit_bruit - 0.5) * noise_strength * 0.12;

	// Petit effet vertical pour éviter que la couleur soit trop plate.
	float ombrage_vertical = sin(position_monde.y * 0.8) * shade_strength * 0.18;

	// Valeur finale utilisée pour choisir la couleur.
	float valeur_couleur = temperature_ratio + variation + ombrage_vertical;
	valeur_couleur = clamp(valeur_couleur, 0.0, 1.0);

	vec3 couleur = couleur_thermique(valeur_couleur);

	ALBEDO = couleur;
	EMISSION = couleur * emission_strength;
}
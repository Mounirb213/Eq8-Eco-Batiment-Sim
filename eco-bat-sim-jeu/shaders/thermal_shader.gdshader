shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float temperature_ratio : hint_range(0.0, 1.0) = 0.5;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.12;
uniform float shade_strength : hint_range(0.0, 0.5) = 0.18;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.65;

varying vec3 world_position;


float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}


float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float n000 = hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);

	return mix(nxy0, nxy1, f.z);
}


vec3 thermal_color(float t) {
	t = clamp(t, 0.0, 1.0);

	vec3 violet = vec3(0.25, 0.0, 0.85);
	vec3 blue = vec3(0.0, 0.1, 1.0);
	vec3 cyan = vec3(0.0, 0.9, 1.0);
	vec3 green = vec3(0.0, 1.0, 0.1);
	vec3 yellow = vec3(1.0, 1.0, 0.0);
	vec3 orange = vec3(1.0, 0.45, 0.0);
	vec3 red = vec3(1.0, 0.0, 0.0);

	if (t < 0.16) {
		return mix(violet, blue, t / 0.16);
	}

	if (t < 0.32) {
		return mix(blue, cyan, (t - 0.16) / 0.16);
	}

	if (t < 0.48) {
		return mix(cyan, green, (t - 0.32) / 0.16);
	}

	if (t < 0.64) {
		return mix(green, yellow, (t - 0.48) / 0.16);
	}

	if (t < 0.82) {
		return mix(yellow, orange, (t - 0.64) / 0.18);
	}

	return mix(orange, red, (t - 0.82) / 0.18);
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	float n1 = noise(world_position * 0.55);
	float n2 = noise(world_position * 1.25);
	float n3 = noise(world_position * 2.5);

	float variation = 0.0;

	// Gros dégradé doux
	variation += (n1 - 0.5) * noise_strength;

	// Détail moyen, plus léger
	variation += (n2 - 0.5) * noise_strength * 0.35;

	// Petit détail, très discret
	variation += (n3 - 0.5) * noise_strength * 0.12;

	// Variation verticale très douce
	float vertical_shade = sin(world_position.y * 0.8) * shade_strength * 0.18;

	float t = temperature_ratio + variation + vertical_shade;
	t = clamp(t, 0.0, 1.0);

	vec3 color = thermal_color(t);

	ALBEDO = color;
	EMISSION = color * emission_strength;
}
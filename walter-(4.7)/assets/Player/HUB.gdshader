shader_type canvas_item;
// Cristal de casco de buceo v5 (Godot 4.x) - más limpio: menos ruido, texto nítido, opacidad ajustable
// Ponlo en un ColorRect (con un ShaderMaterial) que cubra el interior del marco,
// por debajo de tus iconos y labels.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;

group_uniforms general;
uniform float aspect = 2.2;                 // ancho / alto del ColorRect
uniform bool use_screen_refraction = true;  // true: distorsiona lo que hay detrás. false: solo overlay con alpha
uniform float glass_opacity : hint_range(0.0, 1.0) = 1.0;  // opacidad del cristal completo (distorsión incluida)
uniform float detail_opacity : hint_range(0.0, 1.0) = 1.0; // opacidad de caustics, condensación y grano

group_uniforms shape;
uniform float corner_radius : hint_range(0.0, 1.0) = 0.18;   // radio de las esquinas (0 = cuadradas)
uniform float corner_feather : hint_range(0.005, 0.3) = 0.05; // suavizado del recorte en los lados rectos
uniform float corner_fade : hint_range(0.0, 0.8) = 0.28;      // hasta dónde llega el desvanecido en las esquinas (hacia el centro)
uniform float fade_curve : hint_range(0.5, 3.0) = 1.4;        // >1 = desvanecido más gradual, de poco a poco
uniform float corner_darken : hint_range(0.0, 0.8) = 0.3;     // oscurece las esquinas para fundirlas con el marco

group_uniforms tint;
uniform vec4 glass_tint : source_color = vec4(0.10, 0.38, 0.34, 0.45);
uniform vec4 deep_tint : source_color = vec4(0.01, 0.08, 0.09, 1.0);
uniform float vignette_start : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.75;

group_uniforms refraction;
uniform float refraction : hint_range(0.0, 0.05) = 0.012;
uniform float chroma : hint_range(0.0, 3.0) = 0.4;
uniform float wobble_amount : hint_range(0.0, 0.03) = 0.004;
uniform float blur : hint_range(0.0, 4.0) = 0.6;

group_uniforms reflections;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.35;
uniform float streak_angle : hint_range(0.0, 90.0) = 28.0;
uniform float streak_offset : hint_range(-3.0, 3.0) = -0.9;
uniform vec4 reflection_color : source_color = vec4(0.85, 1.0, 0.95, 1.0);

group_uniforms water;
uniform vec4 caustic_color : source_color = vec4(0.45, 1.0, 0.8, 1.0);
uniform float caustic_strength : hint_range(0.0, 0.5) = 0.06;
uniform float caustic_speed : hint_range(0.0, 1.0) = 0.12;

group_uniforms condensation;
uniform float condensation : hint_range(0.0, 1.0) = 0.35;
uniform vec4 fog_color : source_color = vec4(0.55, 0.8, 0.75, 1.0);
uniform float drop_density : hint_range(10.0, 60.0) = 26.0;

group_uniforms finish;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.2;
uniform float grain : hint_range(0.0, 0.2) = 0.012;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// Distancia con signo a una caja redondeada: negativa dentro, 0 en el borde
float box_sd(vec2 pa, vec2 hs, float rad) {
	float r = min(rad, min(hs.x, hs.y));
	vec2 q = abs(pa) - (hs - vec2(r));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * 2.0 - 1.0;                 // -1..1
	vec2 pa = vec2(p.x * aspect, p.y);       // corregido por aspecto

	// --- Recorte de esquinas redondeadas ---
	float sd = box_sd(pa, vec2(aspect, 1.0), corner_radius);

	// Distancia "superelipse" al borde: 0 en el centro, ~1 en el borde, >1 en esquinas
	float e = pow(abs(p.x), 4.0) + pow(abs(p.y), 4.0);

	// Desvanecido: estrecho en los lados rectos, más ancho (hacia el centro) en las esquinas
	float corner_amt = smoothstep(1.0, 2.0, e);
	float fade_w = max(mix(corner_feather, corner_fade, corner_amt), 0.001);
	float t = clamp(-sd / fade_w, 0.0, 1.0);
	float mask = pow(smoothstep(0.0, 1.0, t), fade_curve);
	float edge = smoothstep(vignette_start, 1.3, e);
	// Oscurece también siguiendo la forma redondeada, para que las esquinas se fundan con el marco
	edge = max(edge, smoothstep(-corner_darken, 0.0, sd));

	// --- Refracción / vidrio curvo ---
	vec2 wob = vec2(
		fbm(pa * 3.0 + vec2(TIME * 0.15, 0.0)),
		fbm(pa * 3.0 + vec2(17.0, -TIME * 0.12))
	) - 0.5;
	vec2 off = p * e * refraction + wob * wobble_amount;

	vec3 base = glass_tint.rgb;
	if (use_screen_refraction) {
		vec2 suv = SCREEN_UV + off;
		base.r = textureLod(screen_tex, suv + off * chroma, blur).r;
		base.g = textureLod(screen_tex, suv, blur).g;
		base.b = textureLod(screen_tex, suv - off * chroma, blur).b;
		base = mix(base, glass_tint.rgb, glass_tint.a);
	}

	vec3 col = base;

	// --- Profundidad: oscurece hacia los bordes ---
	col = mix(col, deep_tint.rgb, clamp(edge * vignette_strength, 0.0, 1.0));

	// --- Caustics suaves (luz que se filtra a través del agua) ---
	float c = fbm(pa * 4.0 + vec2(TIME * caustic_speed, -TIME * caustic_speed * 0.7));
	c = pow(smoothstep(0.45, 0.85, c), 2.0);
	col += caustic_color.rgb * c * caustic_strength * detail_opacity * (1.0 - edge);

	// --- Condensación: niebla + gotitas, más fuerte en los bordes ---
	float fog = fbm(pa * 5.0 + 3.0) * edge;
	col = mix(col, fog_color.rgb, fog * condensation * detail_opacity * 0.45);

	vec2 gv = uv * vec2(aspect * drop_density, drop_density);
	vec2 id = floor(gv);
	vec2 f = fract(gv) - 0.5;
	float h = hash(id);
	vec2 o = (vec2(hash(id + 1.7), hash(id + 9.2)) - 0.5) * 0.5;
	float rad = 0.08 + 0.14 * h;
	float d = length(f - o);
	float drop = smoothstep(rad, rad * 0.55, d) * step(0.6, h);
	float spec = smoothstep(rad * 0.45, 0.0, length(f - o - vec2(-0.05, -0.05))) * step(0.6, h);
	float drop_mask = mix(0.15, 1.0, edge) * condensation * detail_opacity;
	col += fog_color.rgb * drop * 0.10 * drop_mask;
	col += vec3(1.0) * spec * 0.35 * drop_mask;

	// --- Reflejos del cristal ---
	float a = radians(streak_angle);
	vec2 n = vec2(cos(a), sin(a));
	float dd = dot(pa, n);
	float s1 = smoothstep(0.22, 0.0, abs(dd - streak_offset));
	float s2 = smoothstep(0.07, 0.0, abs(dd - (streak_offset + 0.55)));
	float fade = smoothstep(1.0, -0.4, p.y);  // más visible arriba
	float streaks = (s1 * 0.5 + s2 * 0.9) * fade;

	// Arco curvo de brillo arriba a la izquierda
	float ring = abs(length(p * vec2(0.62, 1.0)) - 0.85);
	float arc = smoothstep(0.05, 0.0, ring);
	float arc_mask = smoothstep(0.35, 0.8, dot(normalize(p + 0.0001), normalize(vec2(-0.6, -1.0))));
	arc *= arc_mask;

	col += reflection_color.rgb * (streaks * 0.5 + arc * 0.8) * reflection_strength;

	// --- Aro de borde (fresnel) ---
	float rim = smoothstep(0.75, 1.15, e);
	col += caustic_color.rgb * rim * rim_strength * 0.25;

	// --- Grano ---
	col += (hash(uv * 800.0 + fract(TIME)) - 0.5) * grain * detail_opacity;

	float alpha = 1.0;
	if (!use_screen_refraction) {
		alpha = clamp(glass_tint.a + edge * 0.5 + (streaks + arc) * reflection_strength, 0.0, 1.0);
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), alpha * mask * glass_opacity);
}
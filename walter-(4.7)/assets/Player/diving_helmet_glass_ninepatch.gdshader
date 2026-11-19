shader_type canvas_item;
// Cristal de casco de buceo para aplicar DIRECTAMENTE en un NinePatchRect (Godot 4.x)
// Usa el color de la textura como base, mezcla la refracción de lo que hay detrás
// y solo afecta al interior (no toca el marco).S
// Necesita que un script le pase rect_size (ver ninepatch_glass.gd).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;

group_uniforms frame;
uniform vec2 rect_size = vec2(420.0, 200.0);                      // lo rellena el script
uniform vec4 frame_margin = vec4(40.0, 40.0, 40.0, 40.0);          // grosor del marco en px: izq, arriba, der, abajo

group_uniforms shape;
uniform float corner_radius : hint_range(0.0, 1.0) = 0.18;         // esquinas del cristal (0 = cuadradas)
uniform float inside_feather : hint_range(0.001, 0.2) = 0.02;      // suavizado donde termina el efecto y empieza el marco
uniform float edge_width : hint_range(0.01, 0.6) = 0.10;           // sombra en los lados rectos
uniform float corner_fade : hint_range(0.0, 0.8) = 0.35;           // sombra/desvanecido en las esquinas (hacia el centro)
uniform float fade_curve : hint_range(0.5, 3.0) = 1.2;             // gradualidad de esa sombra

group_uniforms opacity;
uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;         // opacidad de TODO el efecto sobre tu textura
uniform float detail_opacity : hint_range(0.0, 1.0) = 1.0;         // opacidad de caustics, condensación y grano

group_uniforms screen_refraction;
uniform bool use_screen_refraction = true;
uniform float screen_mix : hint_range(0.0, 1.0) = 0.35;           // cuánto se ve lo de detrás a través del cristal
uniform float refraction : hint_range(0.0, 0.05) = 0.012;         // fuerza de la deformación (más hacia los bordes)
uniform float chroma : hint_range(0.0, 3.0) = 0.8;                // aberración cromática
uniform float wobble_amount : hint_range(0.0, 0.03) = 0.003;      // ondeo suave
uniform float blur : hint_range(0.0, 4.0) = 0.8;                  // desenfoque de lo de detrás

group_uniforms tint;
uniform vec4 glass_tint : source_color = vec4(0.10, 0.38, 0.34, 0.25);
uniform vec4 deep_tint : source_color = vec4(0.01, 0.08, 0.09, 1.0);
uniform float vignette_start : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.7;

group_uniforms reflections;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.3;
uniform float streak_angle : hint_range(0.0, 90.0) = 28.0;
uniform float streak_offset : hint_range(-3.0, 3.0) = -0.9;
uniform vec4 reflection_color : source_color = vec4(0.85, 1.0, 0.95, 1.0);

group_uniforms water;
uniform vec4 caustic_color : source_color = vec4(0.45, 1.0, 0.8, 1.0);
uniform float caustic_strength : hint_range(0.0, 0.5) = 0.08;
uniform float caustic_speed : hint_range(0.0, 1.0) = 0.12;

group_uniforms condensation;
uniform float condensation : hint_range(0.0, 1.0) = 0.5;
uniform vec4 fog_color : source_color = vec4(0.55, 0.8, 0.75, 1.0);
uniform float drop_density : hint_range(10.0, 60.0) = 26.0;

group_uniforms finish;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;
uniform float grain : hint_range(0.0, 0.2) = 0.015;

varying vec2 local_pos;

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

float box_sd(vec2 pa, vec2 hs, float rad) {
	float r = min(rad, min(hs.x, hs.y));
	vec2 q = abs(pa) - (hs - vec2(r));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void vertex() {
	// UV en un NinePatchRect va por parches; la posición local sí recorre todo el nodo
	local_pos = VERTEX;
}

void fragment() {
	// En fragment, COLOR ya trae la textura del NinePatch multiplicada por el modulate
	vec4 tex = COLOR;

	// --- Coordenadas normalizadas SOLO del interior del marco ---
	vec2 inner_size = max(rect_size - vec2(frame_margin.x + frame_margin.z, frame_margin.y + frame_margin.w), vec2(1.0));
	vec2 inner_center = vec2(frame_margin.x, frame_margin.y) + inner_size * 0.5;
	vec2 p = (local_pos - inner_center) / (inner_size * 0.5);   // -1..1 dentro del interior
	float aspect = inner_size.x / inner_size.y;
	vec2 uv = p * 0.5 + 0.5;
	vec2 pa = vec2(p.x * aspect, p.y);

	// --- Forma del cristal y máscara del interior ---
	float sd = box_sd(pa, vec2(aspect, 1.0), corner_radius);
	float inside = 1.0 - smoothstep(-inside_feather, inside_feather, sd);

	// Vignette tipo superelipse
	float e = pow(abs(p.x), 4.0) + pow(abs(p.y), 4.0);
	float e_edge = smoothstep(vignette_start, 1.3, e);

	// Sombra siguiendo la forma redondeada: estrecha en lados, ancha en esquinas, gradual
	float corner_amt = smoothstep(1.0, 2.0, e);
	float w = max(mix(edge_width, corner_fade, corner_amt), 0.001);
	float t = clamp(-sd / w, 0.0, 1.0);
	float sd_edge = pow(1.0 - smoothstep(0.0, 1.0, t), fade_curve);

	float edge = max(e_edge, sd_edge);

	// --- Base: la textura de tu NinePatch ---
	vec3 base = tex.rgb;

	// --- Refracción de pantalla: lo que hay detrás, deformado hacia los bordes ---
	if (use_screen_refraction) {
		vec2 wob = vec2(
			fbm(pa * 3.0 + vec2(TIME * 0.15, 0.0)),
			fbm(pa * 3.0 + vec2(17.0, -TIME * 0.12))
		) - 0.5;
		vec2 off = p * e * refraction + wob * wobble_amount;
		vec2 suv = SCREEN_UV + off;
		vec3 scr;
		scr.r = textureLod(screen_tex, suv + off * chroma, blur).r;
		scr.g = textureLod(screen_tex, suv, blur).g;
		scr.b = textureLod(screen_tex, suv - off * chroma, blur).b;
		base = mix(base, scr, screen_mix);
	}

	// --- Tinte suave ---
	vec3 col = mix(base, glass_tint.rgb, glass_tint.a);

	// --- Profundidad: oscurece hacia los bordes ---
	col = mix(col, deep_tint.rgb, clamp(edge * vignette_strength, 0.0, 1.0));

	// --- Caustics ---
	float c = fbm(pa * 4.0 + vec2(TIME * caustic_speed, -TIME * caustic_speed * 0.7));
	c = pow(smoothstep(0.45, 0.85, c), 2.0);
	col += caustic_color.rgb * c * caustic_strength * detail_opacity * (1.0 - edge);

	// --- Condensación ---
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

	// --- Reflejos ---
	float a = radians(streak_angle);
	vec2 n = vec2(cos(a), sin(a));
	float dd = dot(pa, n);
	float s1 = smoothstep(0.22, 0.0, abs(dd - streak_offset));
	float s2 = smoothstep(0.07, 0.0, abs(dd - (streak_offset + 0.55)));
	float fade = smoothstep(1.0, -0.4, p.y);
	float streaks = (s1 * 0.5 + s2 * 0.9) * fade;

	float ring = abs(length(p * vec2(0.62, 1.0)) - 0.85);
	float arc = smoothstep(0.05, 0.0, ring);
	float arc_mask = smoothstep(0.35, 0.8, dot(normalize(p + 0.0001), normalize(vec2(-0.6, -1.0))));
	arc *= arc_mask;

	col += reflection_color.rgb * (streaks * 0.5 + arc * 0.8) * reflection_strength;

	// --- Aro de borde ---
	float rim = smoothstep(0.75, 1.15, e);
	col += caustic_color.rgb * rim * rim_strength * 0.25;

	// --- Grano ---
	col += (hash(uv * 800.0 + fract(TIME)) - 0.5) * grain * detail_opacity;

	// El efecto solo se aplica dentro del interior; el marco queda intacto
	COLOR = vec4(mix(tex.rgb, clamp(col, 0.0, 1.0), inside * effect_opacity), tex.a);
}
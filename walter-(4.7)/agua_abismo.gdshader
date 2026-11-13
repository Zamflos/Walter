shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

group_uniforms Distorsion;
uniform float fuerza_distorsion : hint_range(0.0, 0.02) = 0.0035;
uniform float escala_corriente : hint_range(0.5, 10.0) = 3.0;
uniform float velocidad_corriente : hint_range(0.0, 2.0) = 0.25;
uniform float aberracion_cromatica : hint_range(0.0, 0.02) = 0.0015;

group_uniforms Color_y_Profundidad;
uniform float profundidad : hint_range(0.0, 1.0) = 0.7;
uniform vec4 color_sombras : source_color = vec4(0.03, 0.09, 0.09, 1.0);
uniform vec4 color_luces : source_color = vec4(0.40, 0.80, 0.65, 1.0);
uniform vec4 color_niebla : source_color = vec4(0.04, 0.11, 0.09, 1.0);
uniform float brillo : hint_range(0.5, 2.5) = 1.15;
uniform float intensidad_tinte : hint_range(0.0, 1.0) = 0.45;
uniform float saturacion : hint_range(0.0, 1.5) = 0.9;
uniform float contraste : hint_range(0.5, 1.8) = 1.05;
uniform float intensidad_niebla : hint_range(0.0, 1.0) = 0.22;

group_uniforms Corrupcion;
uniform vec4 color_corrupcion : source_color = vec4(0.42, 0.58, 0.10, 1.0);
uniform float nivel_corrupcion : hint_range(0.0, 1.0) = 0.2;
uniform float velocidad_pulso : hint_range(0.0, 6.0) = 1.2;

group_uniforms Luz;
uniform float intensidad_rayos : hint_range(0.0, 2.0) = 0.7;
uniform float intensidad_caustica : hint_range(0.0, 2.0) = 0.6;
uniform vec2 posicion_jugador = vec2(0.5, 0.5);
uniform float radio_luz : hint_range(0.05, 1.0) = 0.65;
uniform float intensidad_luz_jugador : hint_range(0.0, 1.0) = 0.75;
uniform float intensidad_glow : hint_range(0.0, 2.0) = 0.6;
uniform float umbral_glow : hint_range(0.0, 1.0) = 0.45;
uniform float radio_glow : hint_range(1.0, 20.0) = 6.0;

group_uniforms Atmosfera;
uniform float intensidad_burbujas : hint_range(0.0, 2.0) = 0.9;
uniform float frecuencia_burbujas : hint_range(0.0, 1.0) = 0.12;
uniform float tamano_celda_burbujas : hint_range(100.0, 1500.0) = 450.0;
uniform float oscuridad_base : hint_range(0.0, 0.9) = 0.0;
uniform float oscuridad_profundidad : hint_range(0.0, 0.9) = 0.25;
uniform float vineta : hint_range(0.0, 1.5) = 0.15;
uniform float grano : hint_range(0.0, 0.15) = 0.03;

group_uniforms Camara;
uniform vec2 offset_camara = vec2(0.0);
uniform float zoom_camara = 1.0;
uniform vec2 tamano_viewport = vec2(1920.0, 1080.0);
group_uniforms;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Ruido de gradiente (Perlin): no deja lineas ni cuadros alineados a la rejilla
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float n00 = dot(hash22(i) * 2.0 - 1.0, f);
	float n10 = dot(hash22(i + vec2(1.0, 0.0)) * 2.0 - 1.0, f - vec2(1.0, 0.0));
	float n01 = dot(hash22(i + vec2(0.0, 1.0)) * 2.0 - 1.0, f - vec2(0.0, 1.0));
	float n11 = dot(hash22(i + vec2(1.0, 1.0)) * 2.0 - 1.0, f - vec2(1.0, 1.0));
	float raw = mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
	return clamp(raw + 0.5, 0.0, 1.0);
}

// Cada octava se rota para romper cualquier patron de rejilla
const mat2 ROT = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p = ROT * p * 2.0 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

float fbm2(vec2 p) {
	float v = 0.5 * vnoise(p);
	p = ROT * p * 2.0 + vec2(17.0, 9.0);
	v += 0.25 * vnoise(p);
	return v * 1.1667;
}

float burbujas_capa(vec2 mundo, float t, float celda, float vel, float freq) {
	vec2 p = mundo / celda;
	float col_id = floor(p.x);
	float vel_col = 0.7 + 0.6 * hash21(vec2(col_id, 3.7));
	p.y += t * vel * vel_col;
	vec2 id = floor(p);
	vec2 f = fract(p) - 0.5;
	float h = hash21(id);
	vec2 off = (vec2(hash21(id + 7.3), hash21(id + 1.9)) - 0.5) * 0.5;
	off.x += sin(t * 1.3 + h * 6.28) * 0.1;
	float r = mix(0.04, 0.12, fract(h * 7.13));
	float d = length(f - off);
	float anillo = smoothstep(r * 0.75, r, d) * (1.0 - smoothstep(r, r * 1.15, d));
	float relleno = (1.0 - smoothstep(0.0, r, d)) * 0.12;
	float reflejo = 1.0 - smoothstep(0.0, r * 0.3, length(f - off - vec2(-r * 0.35, -r * 0.35)));
	float existe = step(1.0 - freq, h);
	return (anillo * 0.8 + relleno + reflejo * 0.9) * existe;
}

void fragment() {
	float t = TIME;
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 pc = vec2(uv.x * aspect, uv.y);
	float dist_centro = length((uv - 0.5) * vec2(aspect, 1.0));
	float prof = clamp(profundidad, 0.0, 1.0);

	float pulso = 0.5 + 0.5 * sin(t * velocidad_pulso);
	pulso *= pulso;
	float latido = mix(0.75, 1.0, pulso);

	float base_vetas = fbm(pc * 2.5 + vec2(t * 0.03, -t * 0.02));
	float crudo = dist_centro * 1.15 + (base_vetas - 0.45) * 0.9;
	float masc_corr = smoothstep(0.9 - nivel_corrupcion * 0.8, 1.2, crudo) * min(nivel_corrupcion * 4.0, 1.0);

	vec2 q = pc * escala_corriente;
	vec2 flujo = vec2(
		vnoise(q + vec2(t * velocidad_corriente, 0.0)),
		vnoise(q + vec2(5.2, 1.3) - vec2(0.0, t * velocidad_corriente))
	) - 0.5;
	vec2 ondas = vec2(sin(uv.y * 6.0 + t * 0.8), cos(uv.x * aspect * 5.0 + t * 0.7)) * 0.3;
	float fuerza = fuerza_distorsion * (1.0 + masc_corr * 1.5 * latido);
	vec2 uvd = uv + (flujo * 2.0 + ondas) * fuerza;
	uvd = clamp(uvd, vec2(0.002), vec2(0.998));

	vec2 dir = uvd - 0.5;
	float ab = aberracion_cromatica * (dot(dir, dir) * 4.0) * (1.0 + masc_corr * 1.5);
	vec3 col;
	col.r = texture(screen_texture, uvd + dir * ab).r;
	col.g = texture(screen_texture, uvd).g;
	col.b = texture(screen_texture, uvd - dir * ab).b;

	if (intensidad_glow > 0.0) {
		vec2 px = SCREEN_PIXEL_SIZE * radio_glow;
		vec3 g = texture(screen_texture, uvd + vec2(px.x, 0.0)).rgb
			+ texture(screen_texture, uvd - vec2(px.x, 0.0)).rgb
			+ texture(screen_texture, uvd + vec2(0.0, px.y)).rgb
			+ texture(screen_texture, uvd - vec2(0.0, px.y)).rgb;
		g *= 0.25;
		float lg = dot(g, vec3(0.299, 0.587, 0.114));
		col += g * smoothstep(umbral_glow, 1.0, lg) * intensidad_glow;
	}

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturacion * (1.0 - prof * 0.3));
	col = (col - 0.5) * contraste + 0.5;
	col = max(col, vec3(0.0));
	vec3 mapa = mix(color_sombras.rgb, color_luces.rgb, smoothstep(0.0, 0.9, lum));
	col = mix(col, col * mapa * 3.0 + color_sombras.rgb * 0.3, intensidad_tinte);
	col *= brillo;

	float nubes = fbm2(pc * 1.6 + vec2(t * 0.015, t * 0.01));
	float f = intensidad_niebla * (0.35 + 0.65 * prof) * (0.5 + nubes);
	vec3 niebla_col = mix(color_niebla.rgb, color_corrupcion.rgb * 0.3, masc_corr);
	col = mix(col, niebla_col, clamp(f, 0.0, 1.0));

	float luz_sup = 1.0 - prof;
	if (luz_sup > 0.02) {
		float alto = pow(1.0 - uv.y, 1.6);
		float a = pc.x + uv.y * 0.45;
		float r1 = vnoise(vec2(a * 5.0 + t * 0.07, t * 0.15));
		float r2 = vnoise(vec2(a * 11.0 - t * 0.05, t * 0.1 + 3.0));
		float rayos = smoothstep(0.45, 0.95, r1 * 0.6 + r2 * 0.4) * alto * luz_sup * intensidad_rayos;

		vec2 pcs = pc * 3.0 + flujo * 1.5;
		float c1 = 1.0 - abs(vnoise(pcs + vec2(t * 0.12, t * 0.08)) * 2.0 - 1.0);
		float c2 = 1.0 - abs(vnoise(pcs * 1.4 - vec2(t * 0.1, -t * 0.06)) * 2.0 - 1.0);
		float caust = pow(c1 * c2, 4.0) * (0.4 + 0.6 * alto) * luz_sup * intensidad_caustica;
		col += color_luces.rgb * (rayos * 0.6 + caust * 0.5);
	}

	float vn = 1.0 - abs(vnoise(pc * 4.0 + vec2(t * 0.04, t * 0.02)) * 2.0 - 1.0);
	float venas = pow(max(vn, 0.0), 6.0);
	vec3 cc = color_corrupcion.rgb;
	col = mix(col, col * vec3(0.82, 0.95, 0.62) + cc * 0.10, masc_corr * 0.6);
	col += cc * venas * masc_corr * 1.4 * mix(0.7, 1.0, pulso);

	if (intensidad_burbujas > 0.0 && frecuencia_burbujas > 0.0) {
		vec2 mundo = offset_camara + uv * tamano_viewport / zoom_camara;
		float burb = burbujas_capa(mundo, t, tamano_celda_burbujas, 0.15, frecuencia_burbujas)
			+ 0.6 * burbujas_capa(mundo + vec2(137.0, 59.0), t, tamano_celda_burbujas * 0.6, 0.25, frecuencia_burbujas);
		col += mix(vec3(0.7, 0.95, 1.0), cc * 1.8, masc_corr) * burb * intensidad_burbujas * 0.5;
	}

	float luz_j = 1.0 - smoothstep(0.0, radio_luz, length((uv - posicion_jugador) * vec2(aspect, 1.0)));
	luz_j *= 0.96 + 0.04 * sin(t * 3.1) * sin(t * 7.3);
	float vin = smoothstep(0.4, 1.2, dist_centro) * vineta;
	float oscuridad = clamp(oscuridad_base + prof * oscuridad_profundidad + vin, 0.0, 0.95);
	oscuridad *= 1.0 - luz_j * intensidad_luz_jugador;
	col *= 1.0 - oscuridad;
	col += color_luces.rgb * luz_j * intensidad_luz_jugador * 0.04;

	col += (hash21(FRAGCOORD.xy + fract(t) * 91.7) - 0.5) * grano;

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
shader_type canvas_item;

// Cambiamos filter_nearest por filter_linear para eliminar las rayas al ondular
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform vec4 tinte_agua : source_color = vec4(0.05, 0.35, 0.55, 1.0);
uniform float intensidad_tinte : hint_range(0.0, 1.0) = 0.25;
uniform float velocidad_olas : hint_range(0.0, 10.0) = 2.0;
uniform float frecuencia_olas : hint_range(1.0, 50.0) = 15.0;
uniform float fuerza_distorsion : hint_range(0.0, 0.05) = 0.003;

void fragment() {
    vec2 uv_distorsionado = SCREEN_UV;
    
    // Onda suave en X e Y
    uv_distorsionado.x += sin(uv_distorsionado.y * frecuencia_olas + TIME * velocidad_olas) * fuerza_distorsion;
    uv_distorsionado.y += cos(uv_distorsionado.x * frecuencia_olas + TIME * velocidad_olas) * (fuerza_distorsion * 0.5);
    
    // Margen de seguridad un poco más amplio en los bordes
    uv_distorsionado = clamp(uv_distorsionado, vec2(0.005), vec2(0.995));
    
    vec4 color_pantalla = texture(screen_texture, uv_distorsionado);
    vec3 color_final = mix(color_pantalla.rgb, color_pantalla.rgb * tinte_agua.rgb * 1.5, intensidad_tinte);
    
    COLOR = vec4(color_final, 1.0);
}
precision highp float;

in vec2 frag_texcoord;
in vec4 frag_color;

uniform sampler2D albedo_texture;
uniform vec4 albedo_tint;

layout(location=0) out vec4 screen_color;

void main() {
    screen_color = frag_color * texture(albedo_texture, frag_texcoord) * albedo_tint;
}

in vec2 frag_texcoord;
in vec4 frag_color;

uniform Material material;

layout(location=0) out vec4 screen_color;

void main() {
    screen_color = frag_color * texture(material.albedo_texture, frag_texcoord) * material.albedo_tint;
}

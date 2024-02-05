layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord;
layout(location=2) in vec4 color;
layout(location=7) in mat4 MVP;
layout(location=15) in vec4 uv_offset;

out vec2 frag_texcoord;
out vec4 frag_color;
void main() {
    frag_texcoord = (texcoord + uv_offset.xy) * uv_offset.zw;
    frag_color = color;
    gl_Position = MVP * vec4(position, 1.0);
}

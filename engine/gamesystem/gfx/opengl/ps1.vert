layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord;
layout(location=2) in vec4 color;
layout(location=3) in vec3 normal;
layout(location=4) in vec3 tangent;
//layout(location=5) in ivec4 bone_ids;
//layout(location=6) in vec4 bone_weights;
layout(location=7) in mat4 MVP;
layout(location=11) in mat4 modelview;
layout(location=15) in vec4 uv_offset;

out vec3 frag_position;
out vec2 frag_texcoord;
out vec4 frag_color;
//out vec3 frag_normal;
//out vec3 frag_tangent;
//out vec3 frag_bitangent;
out float depth;
out vec3 eyedir;

out mat3 TBN;

//uniform mat4 projection;
uniform float screen_width;
uniform float screen_height;
uniform bool texture_correct;

void main() {

    gl_Position = MVP * vec4(position, 1.0);

    gl_Position.xy = floor((gl_Position.xy + vec2(1.0, 1.0)) * 0.5 * vec2(screen_width, screen_height));
    gl_Position.xy = gl_Position.xy / vec2(screen_width, screen_height) * 2.0 - vec2(1.0, 1.0);

    depth = gl_Position.w;

    //TBN - camera space to tangent space.
    vec3 n = normalize(normal);
    vec3 t = normalize(tangent);
    //re-orthogonalize.
    t = normalize(t - dot(t, n) * n);
    vec3 b = normalize(cross(normal, tangent));
    TBN = transpose(mat3(modelview) * mat3(t, b, n));

    frag_position = vec3(modelview * vec4(position, 1.0));
    eyedir = TBN*(vec3(0, 0, 0) - frag_position);

    if(texture_correct) {
        frag_texcoord = (texcoord + uv_offset.xy) * uv_offset.zw;
        frag_color = color;
    } else {
        frag_texcoord = (texcoord + uv_offset.xy) * uv_offset.zw * depth;
        frag_color = color * depth;
    }
}

#version 330 core
layout (location = 0) out vec4 FragColor;

in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)

uniform vec2 u_resolution;

void render(inout vec3 col, in vec2 uv)
{
    col.rg += uv;
}

void main()
{
    vec2 uv = (2.0f * gl_FragCoord.xy - u_resolution.xy)/ u_resolution.y;

    vec3 col;
    render(col, uv);

    FragColor = vec4(gl_FragCoord);
}
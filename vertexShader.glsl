#version 330 core

layout (location = 0) in vec3 pos; // the position variable has attribute position 0

void main()
{
    gl_Position = vec4(pos, 1.0);
}
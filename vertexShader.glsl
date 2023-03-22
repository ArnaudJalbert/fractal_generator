#version 330 core

in vec3 position;
out vec3 fragPosition;

void main()
{
    fragPosition = position;
    gl_Position = vec4(position, 1.0f);

}
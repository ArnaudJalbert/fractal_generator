#version 330 core
out vec4 FragColor;

in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)

uniform vec4 ourColor; // for testing
uniform int width; // width of the window
uniform int height; // height of the window

void main()
{

    vec2 uv = (2.0f * gl_FragCoord.xy - vec2(width, height))/width;


    FragColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
}
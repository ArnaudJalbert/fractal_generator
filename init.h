//
// Created by Arnaud Jalbert on 2023-03-12.
//

#ifndef FRACTAL_GENERATOR_INIT_H
#define FRACTAL_GENERATOR_INIT_H

#include <iostream>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>

using namespace std;

#define MAJOR_VERSION 3
#define MINOR_VERSION 3

#define WIDTH 800
#define HEIGHT 800

//
const char *vertexShaderSource = "#version 330 core\n"
                                 "layout (location = 0) in vec3 aPos;\n"
                                 "void main()\n"
                                 "{\n"
                                 "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
                                 "}\0";
const char *fragmentShaderSource = "#version 330 core\n"
                                   "out vec4 FragColor;\n"
                                   "void main()\n"
                                   "{\n"
                                   "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n"
                                   "}\n\0";

// check shader success/failure
int success;
char infoLog[512];

#endif //FRACTAL_GENERATOR_INIT_H

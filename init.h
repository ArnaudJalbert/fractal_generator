
#ifndef FRACTAL_GENERATOR_INIT_H
#define FRACTAL_GENERATOR_INIT_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <random>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/trigonometric.hpp>

using namespace std;
using namespace glm;

#define MAJOR_VERSION 3
#define MINOR_VERSION 3

#define WIDTH 1920
#define HEIGHT 1280

// check shader success/failure
int success;

// fractal mode
int mode = 1;

// to animate
float animate = 1;

// to repeat
int repeat = 0;

// main color of the fractal
vec3 mainColor = vec3(1, 1, 1);
int colorWheel = 0;
float red = 0;
float green = 0.3;
float blue = 1;

std::mt19937 rng;                                       // Random number generator
std::uniform_real_distribution<float> dist(0.0f, 1.0f); // Uniform distribution between 0 and 1

#endif // FRACTAL_GENERATOR_INIT_H

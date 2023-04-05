
#ifndef FRACTAL_GENERATOR_CAMERA_H
#define FRACTAL_GENERATOR_CAMERA_H

#include "init.h"

#define CAMERA_SPEED 0.01f


/*
 * We setup the camera attributes in here
 */

// origin of the camera -> Point
vec3 cameraOrigin = vec3(0, 0, 10);

// lookat direction of the camera -> vector
vec3 cameraLookat = normalize(vec3(0,0,-1));

// up direction of the camera -> vector
vec3 cameraUp = vec3(0,1,0);

// right direction of the camera -> vector
vec3 cameraRight = vec3(1,0,0);

// field of view -> degrees
float fov = 1.2;

// mouse controls
bool firstMouse = true;
float lastX = 0.0f;
float lastY = 0.0f;
float camYaw = -90.0f;
float camPitch = 0.0f;

#endif //FRACTAL_GENERATOR_CAMERA_H

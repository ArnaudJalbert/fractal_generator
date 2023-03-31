
#include "init.h"
#include "camera.h"
#include "light.h"
#include "setup.cpp"

using namespace std;

void sendDataToShader(unsigned int shaderProgram){
    // addresses of all the uniforms variables of the shader program
    // we assign the camera information as well as the resolution and
    GLint resolutionLocation = glGetUniformLocation(shaderProgram, "resolution");
    glUniform2i(resolutionLocation, WIDTH, HEIGHT);

    GLint aspectRatioLocation = glGetUniformLocation(shaderProgram, "aspectRatio");
    glUniform1f(aspectRatioLocation, float(WIDTH)/float(HEIGHT));

    GLint cameraUpLocation = glGetUniformLocation(shaderProgram, "cameraUp");
    glUniform3fv(cameraUpLocation, 1, value_ptr(cameraUp));

    GLint cameraRightLocation = glGetUniformLocation(shaderProgram, "cameraRight");
    glUniform3fv(cameraRightLocation, 1, value_ptr(cameraRight));

    GLint cameraLookatLocation = glGetUniformLocation(shaderProgram, "cameraLookat");
    glUniform3fv(cameraLookatLocation, 1, value_ptr(cameraLookat));

    GLint cameraOriginLocation = glGetUniformLocation(shaderProgram, "cameraOrigin");
    glUniform3fv(cameraOriginLocation, 1, value_ptr(cameraOrigin));

    GLint fovLocation = glGetUniformLocation(shaderProgram, "fov");
    glUniform1f(fovLocation, fov);

    GLint lightPositionLocation = glGetUniformLocation(shaderProgram, "lightPosition");
    glUniform3fv(lightPositionLocation, 1, value_ptr(lightPosition));

    GLint lightIntensityLocation = glGetUniformLocation(shaderProgram, "lightIntensity");
    glUniform1f(lightIntensityLocation, lightIntensity);

    GLint animateLocation = glGetUniformLocation(shaderProgram, "animate");
    glUniform1f(animateLocation, animate);

    GLint modeLocation = glGetUniformLocation(shaderProgram, "mode");
    glUniform1i(modeLocation, mode);

    GLint repeatLocation = glGetUniformLocation(shaderProgram, "repeat");
    glUniform1i(repeatLocation, repeat);

    GLint colorLocation = glGetUniformLocation(shaderProgram, "mainColor");
    glUniform3fv(colorLocation, 1, value_ptr(mainColor));
}

void wasdControl(GLFWwindow* window){

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        cameraOrigin += CAMERA_SPEED * cameraLookat;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        cameraOrigin -= CAMERA_SPEED * cameraLookat;
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        cameraOrigin -= (cross(cameraLookat, cameraUp)) * CAMERA_SPEED;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        cameraOrigin += (cross(cameraLookat, cameraUp)) * CAMERA_SPEED;
}

void mouseControl(GLFWwindow* window, double xpos, double ypos){

    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;
    lastX = xpos;
    lastY = ypos;

    float sensitivity = 0.1f;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    camYaw   += xoffset;
    camPitch += yoffset;

    if(camPitch > 89.0f)
        camPitch = 89.0f;
    if(camPitch < -89.0f)
        camPitch = -89.0f;

    vec3 direction;
    direction.x = cos(radians(camYaw)) * cos(radians(camPitch));
    direction.y = sin(radians(camPitch));
    direction.z = sin(radians(camYaw)) * cos(radians(camPitch));

    cameraLookat = normalize(direction);
    cameraRight = normalize(cross(cameraLookat, vec3(0.0f, 1.0f, 0.0f)));
    cameraUp = normalize(cross(cameraRight, cameraLookat));
}

void arrowsControl(GLFWwindow* window){

    if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS){
        camPitch += 1;

        if(camPitch > 89.0f)
            camPitch = 89.0f;
        if(camPitch < -89.0f)
            camPitch = -89.0f;
    }
    if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS){
        camPitch -= 1;

        if(camPitch > 89.0f)
            camPitch = 89.0f;
        if(camPitch < -89.0f)
            camPitch = -89.0f;
    }
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS){
        camYaw   += 1;
    }
    if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS){
        camYaw  -= 1;
    }

    vec3 direction;
    direction.x = cos(radians(camYaw)) * cos(radians(camPitch));
    direction.y = sin(radians(camPitch));
    direction.z = sin(radians(camYaw)) * cos(radians(camPitch));

    cameraLookat = normalize(direction);
    cameraRight = normalize(cross(cameraLookat, vec3(0.0f, 1.0f, 0.0f)));
    cameraUp = normalize(cross(cameraRight, cameraLookat));
}

void scrollControl(GLFWwindow* window, double xoffset, double yoffset)
{
    rng.seed(std::chrono::system_clock::now().time_since_epoch().count());

    mainColor = vec3(dist(rng),dist(rng),dist(rng));
}

void switchFractals(GLFWwindow* window){

    if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS) {
        mode = 1;
        cameraOrigin = vec3(0,0,3);
    }
    if (glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS) {
        mode = 2;
        cameraOrigin = vec3(0,0,12);
        lightPosition = vec3(0,0,15);
    }
    if (glfwGetKey(window, GLFW_KEY_3) == GLFW_PRESS) {
        mode = 3;
        cameraOrigin = vec3(0,0,10);
    }
    if (glfwGetKey(window, GLFW_KEY_4) == GLFW_PRESS) {
        mode = 4;
        cameraOrigin = vec3(0,0,0);
    }
    if (glfwGetKey(window, GLFW_KEY_5) == GLFW_PRESS) {
        mode = 5;
        cameraOrigin = vec3(0,0,6);
    }
    if (glfwGetKey(window, GLFW_KEY_6) == GLFW_PRESS) {
        mode = 6;
        cameraOrigin = vec3(0,0,15);
        lightPosition = vec3(2,2,25);
    }
    if (glfwGetKey(window, GLFW_KEY_7) == GLFW_PRESS) {
        mode = 7;
        cameraOrigin = vec3(0,0,15);
    }
    if (glfwGetKey(window, GLFW_KEY_8) == GLFW_PRESS) {
        mode = 8;
        cameraOrigin = vec3(0,0,20);
        lightPosition = vec3(5,2,10);
    }
    if (glfwGetKey(window, GLFW_KEY_9) == GLFW_PRESS){
        mode = 9;
        cameraOrigin = vec3(0,0,10);
    }
    if (glfwGetKey(window, GLFW_KEY_0) == GLFW_PRESS){
        mode = 0;
        cameraOrigin = vec3(0,0,7);
    }


    // repeat
    if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
        repeat = 1;
        animate = 0;
    }
    if (glfwGetKey(window, GLFW_KEY_T) == GLFW_PRESS) {
        repeat = 0;
        animate = 0;
    }

}

int main(){

    glfwInit();

    initWindowHint();

    cout << WIDTH << endl;
    cout << HEIGHT << endl;

    GLFWwindow* window = glfwCreateWindow(WIDTH, HEIGHT, "FractalGenerator", NULL, NULL);



    if (window == NULL)
    {
        cout << "Failed to create GLFW window" << endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    glewExperimental = true;
    if (glewInit() != GLEW_OK) {
        std::cerr << "Failed to create GLEW" << std::endl;
        glfwTerminate();
        return -1;
    }

    int screenWidth, screenHeight;

    glfwGetFramebufferSize(window, &screenWidth, &screenHeight);

    // init the opengl window
    glViewport(0, 0, screenWidth, screenHeight);

    // callbacks
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // storing shader information in a string
    string fragmentShaderSource = readShaderFile("../fragmentShader.glsl");

    string vertexShaderSource = readShaderFile("../vertexShader.glsl");

    // shaders init
    unsigned int vertexShader = initVertexShader(vertexShaderSource);

    unsigned int fragmentShader = initFragmentShader(fragmentShaderSource);

    // link shaders
    unsigned int shaderProgram = linkShaders(vertexShader, fragmentShader);
    glUseProgram(shaderProgram);

    // basic rectangle that covers the 4 corners of the screen
    float vertices[] = {
            1,  1, -1,  // top right
            1,  -1, -1,  // bottom right
            -1,  -1, -1,  // bottom left
            -1,  1, -1,   // top left
    };
    unsigned int indices[] = {
            0, 1, 3,   // first triangle
            1, 2, 3    // second triangle
    };

    /*
     * IMPORTANT: I acknowledge that most of this setup is taken from LearnOpenGL.com,
     * I thought it was well made and did it in the training so I kept most of it
     */

    // create VAO, VBO and EBO
    unsigned int VAO, VBO, EBO;

    // creating the vertex array VAO
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    // binding VAO
    glBindVertexArray(VAO);

    // creating the vertex buffers VBO
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // setting the vertex buffer
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // setting the element buffer object
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // mouse control
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glfwSetCursorPosCallback(window, reinterpret_cast<GLFWcursorposfun>(mouseControl));
    glfwSetScrollCallback(window, scrollControl);

    sendDataToShader(shaderProgram);

    // window loop
    while(!glfwWindowShouldClose(window))
    {
        // input
        // -----
        processInput(window);

        // commands
        // --------

        // activate shader
        glUseProgram(shaderProgram);

        // clear background
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // sending vertices to the shader
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        // animate constant
        animate = glfwGetTime();

        wasdControl(window);
        arrowsControl(window);
        switchFractals(window);

        // updated data
        sendDataToShader(shaderProgram);

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfwSwapBuffers(window);
        glfwPollEvents();
    }


    // optional: de-allocate all resources once they've outlived their purpose:
    // ------------------------------------------------------------------------
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteProgram(shaderProgram);

    // properly terminating glfw
    glfwTerminate();
    return 0;
}
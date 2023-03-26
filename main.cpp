
#include "init.h"
#include "camera.h"
#include "light.h"

using namespace std;

void framebuffer_size_callback(GLFWwindow* window, int width, int height){
    glViewport(0, 0, width, height);
};

void processInput(GLFWwindow *window)
{
    if(glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

void initWindowHint(){

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, MAJOR_VERSION);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, MINOR_VERSION);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

}

std::string readShaderFile(const char* filePath)
{
    std::ifstream shaderFile(filePath);
    if (!shaderFile.is_open()) {
        // handle error
        return "";
    }

    std::stringstream shaderStream;
    shaderStream << shaderFile.rdbuf();
    shaderFile.close();

    return shaderStream.str();
}

unsigned int initVertexShader(const string& shaderSource){

    const char* source = shaderSource.c_str();

    // vertex shader init
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &source, NULL);
    glCompileShader(vertexShader);

    // check for shader compile errors
    char infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    return vertexShader;
}

unsigned int initFragmentShader(const string& shaderSource){

    const char* source = shaderSource.c_str();

    // fragment shader
    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &source, NULL);
    glCompileShader(fragmentShader);
    // check for shader compile errors
    char infoLog[512];
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    return fragmentShader;
}

unsigned int linkShaders(unsigned int vertexShader, unsigned int fragmentShader){
    // link shaders
    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    // check for linking errors
    char infoLog[512];
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return shaderProgram;
}

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
    cameraRight = glm::normalize(glm::cross(cameraLookat, cameraUp));
    cameraUp = glm::normalize(glm::cross(cameraRight, cameraLookat));
}

void scrollControl(GLFWwindow* window, double xoffset, double yoffset)
{
    rng.seed(std::chrono::system_clock::now().time_since_epoch().count());

    mainColor = vec3(dist(rng),dist(rng),dist(rng));
}

void switchFractals(GLFWwindow* window){

    if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS)
        mode = 1;
    if (glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS) {
        mode = 2;
        animate = 0;
        cameraOrigin = vec3(0,0,4);
    }
    if (glfwGetKey(window, GLFW_KEY_3) == GLFW_PRESS) {
        mode = 3;
        animate = 0;
    }


    // repeat
    if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
        if (repeat == 1)
            repeat = 0;
        else
            repeat = 1;
    }

}

int main(){

    glfwInit();

    initWindowHint();

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

    // init the opengl window
    glViewport(0, 0, WIDTH, HEIGHT);

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
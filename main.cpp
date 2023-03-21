//
// Created by Arnaud Jalbert on 2023-03-12.
//

// https://learnopengl.com/Getting-started/Hello-Triangle

#include "init.h"

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

    // basic rectangle th
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

    // create VAO and VBO
    unsigned int VAO, VBO, EBO;

    // creating the vertex array
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    // binding arrays
    glBindVertexArray(VAO);

    // creating the vertex buffers
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // setting the vertex buffer
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // setting the element buffer object
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // addresses of all the uniforms of the shader program
    GLint resolutionLocation = glGetUniformLocation(shaderProgram, "u_resolution");
    GLint cameraUpLocation = glGetUniformLocation(shaderProgram, "u_cameraUp");
    GLint cameraRightLocation = glGetUniformLocation(shaderProgram, "u_cameraRight");
    GLint cameraForwardLocation = glGetUniformLocation(shaderProgram, "u_cameraForward");
    GLint cameraPositionLocation = glGetUniformLocation(shaderProgram, "u_cameraPosition");
    GLint focalLengthLocation = glGetUniformLocation(shaderProgram, "u_focalLength");
    GLint aspectRatioLocation = glGetUniformLocation(shaderProgram, "u_aspectRatio");

    // sending resolution to the shader
    glUniform2i(resolutionLocation, float(WIDTH), float(HEIGHT));
    glUniform1f(aspectRatioLocation, float(WIDTH)/float(HEIGHT));

    // window loop
    while(!glfwWindowShouldClose(window))
    {
        // input
        // -----
        processInput(window);

        // commands
        // --------

        glUseProgram(shaderProgram);

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);


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
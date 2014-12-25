

#import "ProgramLoader.h"

@implementation ProgramLoader

+ (GLuint) loadProgramWithVertexShaderFileName:(NSString *) vertexShaderFileName
                            fragmentShaderName:(NSString *) fragmentShaderFileName
{
    GLuint program = glCreateProgram();
    
    GLuint vertexShader = [ProgramLoader loadShaderWithType:GL_VERTEX_SHADER sourceFileName:vertexShaderFileName];
    GLuint fragmentShader = [ProgramLoader loadShaderWithType:GL_FRAGMENT_SHADER sourceFileName:fragmentShaderFileName];
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    int status = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status != GL_TRUE) {
        GLint errorLogLength;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &errorLogLength);
        GLchar *errorLog = (GLchar *)malloc(errorLogLength);
        glGetProgramInfoLog(program, errorLogLength, NULL, errorLog);
        NSLog(@"Fail to Link Program : %s", errorLog);
        free(errorLog);
    }
    
    return program;
}

+ (GLuint) loadShaderWithType:(GLenum) shaderType sourceFileName:(NSString *) sourceFileName
{
    GLuint shader = glCreateShader(shaderType);
    
    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:sourceFileName];
    const char *src = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL] cStringUsingEncoding:NSUTF8StringEncoding];
    glShaderSource(shader, 1, &src, NULL);
    glCompileShader(shader);
    
    int status = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        GLint errorLogLength = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &errorLogLength);
        char *errorLog = (char *)malloc(errorLogLength);
        glGetShaderInfoLog(shader, errorLogLength, NULL, errorLog);
        NSLog(@"Fail to Compile Shader: %s", errorLog);
        free(errorLog);
    }
    
    return shader;
}

@end



#import "OpenGLView.h"
#import "ProgramLoader.h"
#import <GLKit/GLKit.h>
@interface OpenGLView() {
    GLuint colorRenderBuffer;
    GLuint mvpLoc;
    GLuint samplerLoc;
    GLuint frontTexture;
    GLuint leftTexture;
    GLfloat currentRotation;
    GLfloat xTranslation;
    GLfloat zTranslation;
}

@end

typedef struct{
    GLKVector3 position;
    GLKVector2 texture;
}SceneVertex;

static SceneVertex vertices[] = {
    {{-1, -1, 0}, {0, 1}},
    {{-1, 1, 0}, {0, 0}},
    {{1, 1, 0}, {1, 0}},
    {{1, -1, 0}, {1, 1}},
    
    {{-1, -1, 0}, {1, 1}},
    {{-1, 1, 0}, {1, 0}},
    {{-1, 1, -2}, {0, 0}},
    {{-1, -1, -2}, {0, 1}},
};

static GLubyte indices[] = {
    0, 2, 1,
    2, 0, 3,
    
    5, 6, 4,
    4, 6, 7,
};

@implementation OpenGLView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (void) setupLayer
{
    eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
}

- (void) setupContext
{
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:context];
}

- (void) setupRenderBuffer
{
    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
}

- (void) setupFrameBuffer
{
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
}

- (void) setupProgram
{
    GLuint program = [ProgramLoader loadProgramWithVertexShaderFileName:@"Cube.vsl" fragmentShaderName:@"Cube.fsl"];
    glUseProgram(program);
    mvpLoc = glGetUniformLocation(program, "u_mvpMatrix");
    samplerLoc = glGetUniformLocation(program, "s_texture");
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glClearColor(0, 0, 0, 1);
}

- (void) setupVBOs
{
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

- (GLuint) setupTextureWithFile:(NSString *)fileName
{
    CGImageRef image = [UIImage imageNamed:fileName].CGImage;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    GLubyte *data = (GLubyte *)calloc(height * width * 4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(data, width, height, 8, width * 4, CGImageGetColorSpace(image), 1);
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), image);
    CGContextRelease(spriteContext);
    
    GLuint textureName;
    glGenTextures(1, &textureName);
    glBindTexture(GL_TEXTURE_2D, textureName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLint)width, (GLint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    free(data);
    return textureName;
}

- (void) render:(CADisplayLink *)displayLink
{
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    if (currentRotation < 90) {
        currentRotation += displayLink.duration * 90;
        xTranslation += displayLink.duration;
        zTranslation -= displayLink.duration;
        NSLog(@"timestamp = %g", displayLink.timestamp);
    }
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(xTranslation, 0, zTranslation);
    modelView = GLKMatrix4Rotate(modelView, GLKMathDegreesToRadians(currentRotation), 0, 1, 0);
    GLKMatrix4 projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), 1, 0.1, 100);
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(projection, modelView);
    
    glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, &mvpMatrix.m[0]);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), 0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, texture));
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, leftTexture);
    glUniform1i(samplerLoc, 0);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, NULL + 6 * sizeof(GLubyte));
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, frontTexture);
    glUniform1i(samplerLoc, 1);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void) setupDisplayLink
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) setup
{
    xTranslation = 0;
    zTranslation = -1;
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupVBOs];
    frontTexture = [self setupTextureWithFile:@"front.jpg"];
    leftTexture = [self setupTextureWithFile:@"left.jpg"];
    [self setupDisplayLink];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

@end

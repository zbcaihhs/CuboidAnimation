

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>

@interface ProgramLoader : NSObject
+ (GLuint) loadProgramWithVertexShaderFileName:(NSString *) vertexShaderFileName
                            fragmentShaderName:(NSString *) fragmentShaderFileName;

@end

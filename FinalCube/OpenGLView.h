

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <QuartzCore/QuartzCore.h>

@interface OpenGLView : UIView {
    EAGLContext *context;
    CAEAGLLayer *eaglLayer;
}

@end

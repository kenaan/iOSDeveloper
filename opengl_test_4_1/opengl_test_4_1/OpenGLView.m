//
//  OpenGLView.m
//  opengl_test_1
//
//  Created by Kalou on 13-5-12.
//  Copyright (c) 2013年 lijian. All rights reserved.
//

#import "OpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import "GLESUtils.h"

@interface OpenGLView ()
@property (nonatomic, retain) EAGLContext *context;
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)setupProgram;
@end


@implementation OpenGLView

@synthesize context;
@synthesize delegate;
@synthesize positionSlot = _positionSlot;
@synthesize rotate = _rotate;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}
- (id)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
        [self setupLayer];
        [self setupContext];
        [self genTexture];
        [self loadTexture];
//        [self setupProgram];
    }
    return self;
}
- (void)setupLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
//    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (context == NULL)
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
        }
    }

    [EAGLContext setCurrentContext:context];
}

- (void)setupProgram {
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"];
    
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"];
    
    GLuint vertexShader = [GLESUtils loadShader:GL_VERTEX_SHADER withFilepath:vertexShaderPath];
    GLuint fragmentShader = [GLESUtils loadShader:GL_FRAGMENT_SHADER withFilepath:fragmentShaderPath];
    
    _programHandle = glCreateProgram();
    if (!_programHandle) {
        NSLog(@"create program fail");
        return;
    }
    
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    
    glLinkProgram(_programHandle);
    
    GLint linked;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv (_programHandle, GL_INFO_LOG_LENGTH, &infoLen );
        
        if (infoLen > 1)
        {
            char * infoLog = malloc(sizeof(char) * infoLen);
            glGetProgramInfoLog (_programHandle, infoLen, NULL, infoLog );
            NSLog(@"Error linking program:\n%s\n", infoLog );
            
            free (infoLog );
        }
        
        glDeleteProgram(_programHandle);
        _programHandle = 0;
        return;
    }
    glUseProgram(_programHandle);
    
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
}

- (void)genTexture {
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)loadTexture {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
    NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
    UIImage *image = [[UIImage alloc] initWithData:texData];
    if (image == nil)
        NSLog(@"Do real error checking here");
    
    GLuint width = CGImageGetWidth(image.CGImage);
    GLuint height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc( height * width * 4 );
    CGContextRef contextRef = CGBitmapContextCreate( imageData, width, height, 8, 4 * width,
                                                 colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( contextRef, CGRectMake( 0, 0, width, height ) );
    CGContextTranslateCTM( contextRef, 0, height - height );
    CGContextDrawImage( contextRef, CGRectMake( 0, 0, width, height ), image.CGImage );
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, imageData);
    CGContextRelease(contextRef);
    free(imageData);
    [image release];
    [texData release];
}


- (void)drawView
{
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    
//    [delegate drawView:self];
//    [self render];
//    [self renderCube];
    [self renderTexture];
    
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)renderTexture {
    CGFloat vertices1[] = {
        -1.0, -1.0, -2.0,
         1.0, -1.0, -2.0,
         1.0,  1.0, -2.0,
        -1.0,  1.0, -2.0
    };
    
    CGFloat coords[] = {
        0, 0,
        1, 0,
        1, 1,
        0, 1,
    };
    
    glLoadIdentity();
    
    glScalef(0.5, 0.5, 0.5);
    glTranslatef(0.0, 0.0, 2.0);
    glRotatef(_rotate, 1.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glColor4f(0.0, 1.0, 0.0, 1.0);
    
    glVertexPointer(3, GL_FLOAT, 0, vertices1);
    glTexCoordPointer(2, GL_FLOAT, 0, coords);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    CGFloat vertices2[] = {
        1.0, -1.0, -2.0,
        1.0, -1.0, -3.0,
        1.0,  1.0, -3.0,
        1.0,  1.0, -2.0,
    };
    
    glLoadIdentity();
    
    glVertexPointer(3, GL_FLOAT, 0, vertices2);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_TEXTURE_2D);
}

- (void)renderCube {
    glEnable(GL_CULL_FACE);
    /*
     glLoadIdentity();
     
     glClearColor(0.7, 0.7, 0.7, 1.0);
     glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
     
     glShadeModel(GL_SMOOTH);
     GLfloat vertices[] = {
     -0.5f,  0.5f, 0.0f,
     -0.5f, -0.5f, 0.0f,
     0.5f,  0.5f, 0.0f,
     0.5f, -0.5f, 0.0f,
     };
     
     static const GLfloat texCoords[] = {
     0.0, 1.0,
     1.0, 1.0,
     0.0, 0.0,
     1.0, 0.0
     };
     
     // Load the vertex data
     //
     //    GLuint pSlot = _glView.positionSlot;
     //    glVertexAttribPointer(pSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
     //    glEnableVertexAttribArray(pSlot);
     glEnableClientState(GL_TEXTURE_COORD_ARRAY);
     glEnableClientState(GL_VERTEX_ARRAY);
     
     //    glColor4f(1.0, 0.0, 0.0, 1.0);
     glBindTexture(GL_TEXTURE_2D, texture[0]);
     glVertexPointer(3, GL_FLOAT, 0, vertices);
     glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
     // Draw triangle
     //
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     
     glDisableClientState(GL_TEXTURE_COORD_ARRAY);
     glDisableClientState(GL_VERTEX_ARRAY);
     */
    
    const GLfloat squareVertices[] = {
        -0.5f, -0.5f,  0.5f,
        -0.5f,  0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f, -0.5f,  0.5f,
        
        0.5f, -0.5f, -0.5f,
        0.5f,  0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,
        -0.5f, -0.5f, -0.5f,
    };
    
    GLubyte indies[] = {
        0, 3, 2, 0, 2, 1, // front
        7, 5, 4, 7, 6, 5, // back
        0, 1, 6, 0, 6, 7, // left
        3, 4, 5, 3, 5, 2, // right
        1, 2, 5, 1, 5, 6, // top
        0, 7, 4, 0, 4, 3, // bottom
    };
    /*
     const GLbyte indies[] = {
     0, 1, 3, //front
     0, 3, 2,
     5, 4, 6, //back
     5, 6, 7,
     4, 0, 2, //left
     4, 2, 6,
     1, 5, 7, //right
     1, 7, 3,
     2, 3, 7, //top
     2, 7, 6,
     4, 5, 1, //bottom
     4, 1, 0
     };
     */
    CGFloat colors[] = {
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f,
        
        1.0f, 1.0f, 0.0f, 1.0f,
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 1.0f,
    };
    
    const GLfloat squareTexCoords[] = {
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        0.0, 1.0
    };
	GLenum err;
    
    GLfloat _scale = 1.0f;
    
    glLoadIdentity();
    
    glScalef(_scale, _scale, _scale);
    glTranslatef(0.0f, 0.0f, -2.0f);
    glRotatef(_rotate, 0.0f, 1.0f, 0.0f);

    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glColor4f(1.0, 0.0, 0.0, 1.0);
    
    glVertexPointer(3, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
//    glColorPointer(4, GL_FLOAT, 0, colors);
//    glEnableClientState(GL_COLOR_ARRAY);
    
    glDrawElements(GL_TRIANGLES, sizeof(indies)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indies);
    
    glTexCoordPointer(2, GL_FLOAT, 0, squareTexCoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	glEnable(GL_TEXTURE_2D);

	glBindTexture(GL_TEXTURE_2D, texture);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glDisable(GL_TEXTURE_2D);
	
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
	err = glGetError();
	if (err != GL_NO_ERROR)
		NSLog(@"Error in frame. glError: 0x%04X", err);
}


- (void)render {
    glLoadIdentity();
    
    glClearColor(0.7, 0.7, 0.7, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLfloat vertices[] = {
        0.0f,  0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f,  -0.5f, 0.0f };
    
    // Load the vertex data
    //
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices );
    glEnableVertexAttribArray(_positionSlot);
    
    // Draw triangle
    //
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)layoutSubviews
{
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}

- (BOOL)createFramebuffer
{
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
        
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    [delegate setupView:self];
    return YES;
}

- (void)destroyFramebuffer
{
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
}

- (void)toggleDisplayLink {
    if (_displayLink == nil) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallBack:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    } else {
        [_displayLink invalidate];
        [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _displayLink = nil;
    }
}

- (void)displayLinkCallBack:(CADisplayLink*)displayLink
{
//    NSLog(@"%f", displayLink.duration);
    _rotate += displayLink.duration * 90;
    NSLog(@"%f", _rotate);
    
    [self setNeedsLayout];
}


- (void)dealloc
{    
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    [super dealloc];
}

@end

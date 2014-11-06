//
//  GPUFramebuffer.h
//  Movie
//
//  Created by lijian on 14-7-20.
//  Copyright (c) 2014年 lijian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPUFramebuffer : NSObject
{
    GLuint _outputTexture;
    GLuint _framebuffer;
    
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
}

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) GLuint texture;

- (id)initWithSize:(CGSize)framebufferSize;
- (id)initOnlyTextureWithSize:(CGSize)framebufferSize;

- (void)activateFramebuffer;

@end

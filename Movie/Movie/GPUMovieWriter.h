//
//  GPUMovieWriter.h
//  Movie
//
//  Created by lijian on 14-10-20.
//  Copyright (c) 2014年 lijian. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import "GPUContext.h"
#import "GPUProgram.h"
#import "GPUInput.h"
#import "GPUFramebuffer.h"

@interface GPUMovieWriter : NSObject <GPUInput>
{
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_audioInput;
    AVAssetWriterInput *_videoInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    GPUProgram *_program;
    
    GLuint _positionSlot;
    GLuint _textureSlot;
    GLuint _samplerSlot;
}

- (id)initWithURL:(NSURL *)movieURL size:(CGSize)movieSize;

- (BOOL)startWriting;
- (void)cancelWriting;

@end
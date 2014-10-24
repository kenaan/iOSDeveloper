//
//  GPUMovieWriter.m
//  Movie
//
//  Created by lijian on 14-10-20.
//  Copyright (c) 2014年 lijian. All rights reserved.
//

#import "GPUMovieWriter.h"

NSString *const kMovieVertexShaderString = SHADER_STRING
(
 attribute vec4 vPosition;
 attribute vec2 textureCoord;
 
 varying vec2 textureCoordOut;
 
 void main()
 {
     gl_Position = vPosition;
     textureCoordOut = textureCoord;
 }
 );

NSString *const kMovieFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordOut;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordOut).bgra;
 }
 );

@interface GPUMovieWriter ()
{
    GLuint _frameBuffer;
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
    GPUFramebuffer *_inputFrameBuffer;
    
    CMTime startTime;
}
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic) CGSize movieSize;

@end

@implementation GPUMovieWriter

- (id)initWithURL:(NSURL *)movieURL size:(CGSize)movieSize
{
    return [self initWithURL:movieURL size:movieSize fileType:AVFileTypeQuickTimeMovie];
}

- (id)initWithURL:(NSURL *)movieURL size:(CGSize)movieSize fileType:(NSString *)outputFileType
{
    self = [super init];
    if (self) {
        self.movieURL = movieURL;
        self.movieSize = movieSize;
        
        startTime = kCMTimeInvalid;
        
        [GPUContext useImageProcessingContext];
        _program = [[GPUProgram alloc] initWithVertexShaderString:kMovieVertexShaderString fragmentShaderString:kMovieFragmentShaderString];
        
        [_program addAttribute:@"vPosition"];
        [_program addAttribute:@"textureCoord"];
        
        [_program link];
        
        [GPUContext setActiveShaderProgram:_program];

//        runSynchronouslyOnVideoProcessingQueue(^{
            _positionSlot = [_program attributeSlot:@"vPosition"];
            _textureSlot = [_program attributeSlot:@"textureCoord"];
            _samplerSlot = [_program uniformIndex:@"inputImageTexture"];
//        });
        
        [self initWriter];
    }
    return self;
}

- (void)dealloc
{
    [_movieURL release];
    [_assetWriter release];
    [_audioInput release];
    [_videoInput release];
    [_assetWriterInputPixelBufferAdaptor release];
    
    [self destroyFBO];
    
    [super dealloc];
}

#pragma mark - Writer

- (void)initWriter
{
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter assetWriterWithURL:_movieURL fileType:AVFileTypeQuickTimeMovie error:&error] retain];
    if (error) {
        NSLog(@"Error:%@", [error description]);
    }
    
    AVAudioSession *sharedAudioSession = [AVAudioSession sharedInstance];
    double preferredHardwareSampleRate;
    
    if ([sharedAudioSession respondsToSelector:@selector(sampleRate)])
    {
        preferredHardwareSampleRate = [sharedAudioSession sampleRate];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
#pragma clang diagnostic pop
    }
    
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;

    NSDictionary *audioSettings = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                    AVSampleRateKey: [NSNumber numberWithDouble:preferredHardwareSampleRate],
                                    AVNumberOfChannelsKey: [NSNumber numberWithInt:1],
                                    AVChannelLayoutKey: [NSData dataWithBytes:&acl length:sizeof(acl)],
                                    AVEncoderBitRateKey: [ NSNumber numberWithInt:64000]
                                    };
    _audioInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings] retain];
    [_assetWriter addInput:_audioInput];
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:_movieSize.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:_movieSize.height]
                                    };
    
    _videoInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] retain];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:_movieSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:_movieSize.height], kCVPixelBufferHeightKey,
                                                           nil];
    _assetWriterInputPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary] retain];
    
    [_assetWriter addInput:_videoInput];
}

- (BOOL)startWriting
{
    return [_assetWriter startWriting];
}

- (void)cancelWriting
{
    [_assetWriter cancelWriting];
}

#pragma mark - GPUInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    if (CMTIME_IS_INVALID(startTime)) {
//        if (_assetWriter.status != AVAssetWriterStatusWriting) {
//            [_assetWriter startWriting];
//        }
        
        [_assetWriter startSessionAtSourceTime:frameTime];
        startTime = frameTime;
    }
    
    [self draw];
    
    CVPixelBufferRef pixel_buffer = NULL;
    pixel_buffer = _renderTarget;
    CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    if (_videoInput.readyForMoreMediaData && _assetWriter.status == AVAssetWriterStatusWriting) {
        BOOL result = [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixel_buffer withPresentationTime:frameTime];
        if (!result) {
            NSLog(@"appendPixelBuffer failed");
            CMTimeShow(frameTime);
        }
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
}

- (void)setInputFramebuffer:(GPUFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    _inputFrameBuffer = newInputFramebuffer;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    
}

- (void)endProcessing
{
    [_videoInput markAsFinished];
    [_audioInput markAsFinished];
    
    [_assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"write finished");
    }];
}

#pragma mark - Draw

- (void)draw {
    [GPUContext useImageProcessingContext];
    
    [self setFilterFBO];

    [GPUContext setActiveShaderProgram:_program];
    
    const GLfloat squarVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    const GLfloat textureCoordies[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 0, squarVertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, 0, textureCoordies);
    glEnableVertexAttribArray(_textureSlot);
    
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, [_inputFrameBuffer texture]);
    glUniform1i(_samplerSlot, 6);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
}

#pragma mark - FBO

- (void)setFilterFBO
{
    if (!_frameBuffer) {
        [self createFBO];
    }
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _movieSize.width, _movieSize.height);
}

- (void)createFBO
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, [_assetWriterInputPixelBufferAdaptor pixelBufferPool], &_renderTarget);
    CVBufferSetAttachment(_renderTarget, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(_renderTarget, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(_renderTarget, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    
    CVOpenGLESTextureCacheRef textureCacheRef = [[GPUContext sharedImageProcessingContext] coreVideoTextureCache];

    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, _renderTarget, NULL, GL_TEXTURE_2D, GL_RGBA, (int)_movieSize.width, (int)_movieSize.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_renderTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyFBO
{
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (_renderTarget) {
        CVPixelBufferRelease(_renderTarget);
    }
    
    if (_renderTexture) {
        CFRelease(_renderTexture);
    }
}

@end
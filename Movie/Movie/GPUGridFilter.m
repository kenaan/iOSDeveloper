//
//  GPUGridFilter.m
//  Movie
//
//  Created by lijian on 14-7-23.
//  Copyright (c) 2014年 lijian. All rights reserved.
//

#import "GPUGridFilter.h"

#define GRID_TRANSFORM
#define SPACE 0.2

NSString *const kGridVertexShaderString = SHADER_STRING
(
 attribute vec4 vPosition;
 attribute vec2 textureCoord;
 
 uniform highp float angle;
 uniform highp float mid;
 
 varying vec2 textureCoordOut;
 
 void main()
 {
     vec2 v_pos;
     v_pos.x = vPosition.x;
     v_pos.y = vPosition.z;
     
     if (angle > 0.0) {
         float alpha;
         alpha = radians(angle);
         
         mat2 m_Matrix;
         m_Matrix[0][0] = cos(alpha);
         m_Matrix[0][1] = -sin(alpha);
         m_Matrix[1][0] = sin(alpha);
         m_Matrix[1][1] = cos(alpha);
         
         v_pos.x = v_pos.x - mid;
         v_pos = m_Matrix * v_pos;
         v_pos.x =  v_pos.x + mid;
     }
     
     gl_Position = vec4(v_pos.x, vPosition.y, v_pos.y, 1.0);
     textureCoordOut = textureCoord;
 }
 );

@implementation GPUGridFilter

- (id)initWithVertexShaderFromString:(NSString *)vertexShader fragmentShaderFromString:(NSString *)fragmentShader {
    if (!(self = [super initWithVertexShaderFromString:vertexShader fragmentShaderFromString:fragmentShader])) {
        return nil;
    }
    
    _verticalNum = 4;
    _horizontalNum = 4;
    
    _intervalLength = 0.02;
    
    [self initVerticesAndTexutreCoords];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        _angleSlot = [_filterProgram uniformIndex:@"angle"];
        _midSlot = [_filterProgram uniformIndex:@"mid"];
    });

    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShader {
    if (!(self = [self initWithVertexShaderFromString:kGridVertexShaderString fragmentShaderFromString:fragmentShader])) {
        return nil;
    }
    return self;
}

- (id)init {
    if (!(self = [self initWithFragmentShaderFromString:kFilterFragmentShaderString])) {
        return nil;
    }
    return self;
}

- (void)initVerticesAndTexutreCoords {
    float count = _verticalNum * _horizontalNum * 4 * 2;
    _vertices = calloc(count, sizeof(GLfloat));
    _texCoords = calloc(count, sizeof(GLfloat));
    
    float space = _intervalLength;
    float width = (2.0 - (_horizontalNum - 1) * space) / _horizontalNum;
    float height = (2.0 - (_verticalNum - 1) * space) / _verticalNum;
    float cWidth = 1.0 / _horizontalNum;
    float cHeight = 1.0 / _verticalNum;
    float x, y;
    
    for (int row = 0; row < _horizontalNum; row ++) {
        for (int column = 0; column < _verticalNum; column ++) {
            x = y = -1.0f;
            int index = row * _horizontalNum * 4 * 2 + column * 4 * 2;
            _vertices[index + 0] = x + (width + space) * row;
            _vertices[index + 1] = y + (height + space) * column;
            _vertices[index + 2] = _vertices[index + 0] + width;
            _vertices[index + 3] = _vertices[index + 1];
            _vertices[index + 4] = _vertices[index + 0];
            _vertices[index + 5] = _vertices[index + 1] + height;
            _vertices[index + 6] = _vertices[index + 0] + width;
            _vertices[index + 7] = _vertices[index + 1] + height;
            
            x = y = 0.0f;
            _texCoords[index + 0] = x + cWidth * row;
            _texCoords[index + 1] = y + cHeight * column;
            _texCoords[index + 2] = _texCoords[index + 0] + cWidth;
            _texCoords[index + 3] = _texCoords[index + 1];
            _texCoords[index + 4] = _texCoords[index + 0];
            _texCoords[index + 5] = _texCoords[index + 1] + cHeight;
            _texCoords[index + 6] = _texCoords[index + 0] + cWidth;
            _texCoords[index + 7] = _texCoords[index + 1] + cHeight;
            
        }
    }
}

#pragma mark -

- (void)setHorizontalNum:(NSInteger)horizontalNum {
    if (horizontalNum) {
        _horizontalNum = horizontalNum;
    }
}

- (void)setVerticalNum:(NSInteger)verticalNum {
    if (verticalNum) {
        _verticalNum = verticalNum;
    }
}

- (void)setIntervalLength:(float)intervalLength {
    if (intervalLength && intervalLength < 1.0) {
        _intervalLength = intervalLength;
    }
}

#pragma mark - 

- (void)draw {
    [GPUContext setActiveShaderProgram:_filterProgram];
    
    if (!_outputFramebuffer) {
        _outputFramebuffer = [[GPUFramebuffer alloc] initWithSize:_textureSize];
    }
    
    [_outputFramebuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    for (int i = 0; i < _horizontalNum; i++) {
        for (int j = 0; j < _verticalNum; j++) {
            int index = i * _horizontalNum * 4 * 2 + j * 4 * 2;
#ifdef GRID_TRANSFORM
            float mid = 0;
            int squar = j*4 + i;
            if (squar == 10) {
                glUniform1f(_angleSlot, 1.4 * _currentFrameIndex);
                mid = (_vertices[index] + _vertices[index + 2]) / 2.0;
                glUniform1f(_midSlot, mid);
            }
            else if (squar == 6) {
                glUniform1f(_angleSlot, 1.3 * _currentFrameIndex);
                mid = (_vertices[index] + _vertices[index + 2]) / 2.0;
                glUniform1f(_midSlot, mid);
            }
            else if (squar == 13) {
                glUniform1f(_angleSlot, 1.2 * _currentFrameIndex);
                mid = (_vertices[index] + _vertices[index + 2]) / 2.0;
                glUniform1f(_midSlot, mid);
            }
            else if (squar == 8) {
                glUniform1f(_angleSlot, 1.1 * _currentFrameIndex);
                mid = (_vertices[index] + _vertices[index + 2]) / 2.0;
                glUniform1f(_midSlot, mid);
            }
            else if (squar == 5) {
                glUniform1f(_angleSlot, 1.0 * _currentFrameIndex);
                mid = (_vertices[index] + _vertices[index + 2]) / 2.0;
                glUniform1f(_midSlot, mid);
            }
            else {
                glUniform1f(_angleSlot, 0.0);
            }
#else 
          glUniform1f(_angleSlot, 0.0);
#endif
            
            [self renderToTextureWithVertices:(_vertices + index)  textureCoordinates:(_texCoords + index)];
        }
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [_firstInputFramebuffer texture]);
    glUniform1i(_samplerSlot, 2);
    
    glEnableVertexAttribArray(_positionAttribute);
    glEnableVertexAttribArray(_textureCoordinateAttribute);
    
    glVertexAttribPointer(_positionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(_textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end

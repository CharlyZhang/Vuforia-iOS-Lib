//
//  AREAGLView.m
//  ARDemo
//
//  Created by CharlyZhang on 16/7/13.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "AREAGLView.h"

#import "ModelFactory.hpp"
#import "CZObjModel.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <Vuforia/Vuforia.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/VideoBackgroundConfig.h>
#include <map>
#include <string>

//#define LOAD_BUNDLE
using namespace std;

typedef map<CZImage*,short> TextureMap;
typedef map<string, CZObjModel*> ModelMap;

const float kObjectScaleNormal = 3.0f;
const float kObjectScaleOffTargetTracking = 12.0f;

@interface AREAGLView ()
{
@private
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    
    // Texture used when rendering augmentation
    GLuint textures[128];
    TextureMap textureMap;
    
    BOOL offTargetTrackingEnabled;
    
    ModelMap modelsMap;
    
    Vuforia::Matrix44F translateMat, scaleMat, rotateMat;
}

@property (nonatomic, weak) SampleApplicationSession * vapp;


- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end

@implementation AREAGLView

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app modelsConfig:(NSDictionary*)configs
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }
        
        //
        textureMap.clear();
        modelsMap.clear();
        for(auto i = 0; i < 128; i ++) textures[i] = -1;
        
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        offTargetTrackingEnabled = NO;
        
        [self loadModels:configs];
        [self initShaders];
        
        SampleApplicationUtils::checkGlError("Inital!");
        
        SampleApplicationUtils::setIndentityMatrix(translateMat.data);
        SampleApplicationUtils::setIndentityMatrix(scaleMat.data);
        SampleApplicationUtils::setIndentityMatrix(rotateMat.data);
        
    }
    
    return self;
}


- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    for (auto i = 0; i < 128 && textures[i] != -1; i++)
        glDeleteTextures(1, &textures[i]);
    textureMap.clear();
    for(ModelMap::iterator itr = modelsMap.begin(); itr != modelsMap.end(); itr++)
        delete itr->second;
    modelsMap.clear();
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}

- (void) loadModels:(NSDictionary *)configs {
    for (NSString *modelName in configs)
    {
        string name([modelName UTF8String]);
        NSString *modelPath = [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:configs[modelName]];
        CZObjModel *model = ModelFactory::createObjModel([modelPath UTF8String]);
        if(model)
            modelsMap[name] = model;
        else
            NSLog(@"model(%@) loading failed!",modelPath);
    }
}

//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
//
// *** Vuforia will call this method periodically on a background thread ***
- (void)renderFrameVuforia
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    Vuforia::State state = Vuforia::Renderer::getInstance().begin();
    Vuforia::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    if (offTargetTrackingEnabled) {
        glDisable(GL_CULL_FACE);
    } else {
        glEnable(GL_CULL_FACE);
    }
    glCullFace(GL_BACK);
    if(Vuforia::Renderer::getInstance().getVideoBackgroundConfig().mReflection == Vuforia::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    // Set the viewport
    glViewport(vapp.viewport.posX, vapp.viewport.posY, vapp.viewport.sizeX, vapp.viewport.sizeY);
    
    static int iTrackResultNumber = 0;
    if(state.getNumTrackableResults() != iTrackResultNumber)
    {
        iTrackResultNumber = state.getNumTrackableResults();
        NSLog(@"track results number %d",iTrackResultNumber);
    }
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);
        const Vuforia::Trackable& trackable = result->getTrackable();
        
        //const Vuforia::Trackable& trackable = result->getTrackable();
        Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());
        
        // OpenGL 2
        Vuforia::Matrix44F modelViewProjection;
        
        if (offTargetTrackingEnabled) {
            SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0,&modelViewMatrix.data[0]);
            SampleApplicationUtils::scalePoseMatrix(kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, &modelViewMatrix.data[0]);
        } else {
            SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, &modelViewMatrix.data[0]);
            SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
        }
        
        Vuforia::Matrix44F modelMat,mat;
        SampleApplicationUtils::multiplyMatrix(scaleMat.data, rotateMat.data, mat.data);
        SampleApplicationUtils::multiplyMatrix(translateMat.data, mat.data, modelMat.data);
        SampleApplicationUtils::multiplyMatrix(modelViewMatrix.data, modelMat.data, mat.data);
        SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &mat.data[0], &modelViewProjection.data[0]);
        
        glUseProgram(shaderProgramID);
        
        CZObjModel *pModel = modelsMap[string(trackable.getName())];
        if (pModel) {
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)pModel->positions.data());
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)pModel->normals.data());
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)pModel->texcoords.data());
        }
        
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
        
        SampleApplicationUtils::checkGlError("before active texture!");
        glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
        
        SampleApplicationUtils::checkGlError("after transform uniform!");
        
        if (pModel) {
            for (std::vector<CZGeometry*>::iterator itr = pModel->geometries.begin(); itr != pModel->geometries.end(); itr++)
            {
                CZGeometry *pGeometry = *itr;
                CZMaterial *pMaterial = pModel->materialLib.get(pGeometry->materialName);
                [self enableTexture:pMaterial->texImage];
                glDrawArrays(GL_TRIANGLES, (GLint)pGeometry->firstIdx, (GLsizei)pGeometry->vertNum);
                
            }
        }
        
        glDisableVertexAttribArray(vertexHandle);
        glDisableVertexAttribArray(normalHandle);
        glDisableVertexAttribArray(textureCoordHandle);
        
        SampleApplicationUtils::checkGlError("EAGLView renderFrameVuforia");
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    Vuforia::Renderer::getInstance().end();
    [self presentFramebuffer];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
#ifdef LOAD_BUNDLE
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"ARResources.bundle/Simple.vertsh"
                                                                   fragmentShaderFileName:@"ARResources.bundle/Simple.fragsh"];
#else
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                                   fragmentShaderFileName:@"Simple.fragsh"];
#endif
    
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void) rotateWithX:(float)x Y:(float)y
{
    Vuforia::Matrix44F tempMat1, tempMat2;
    SampleApplicationUtils::setRotationMatrix(x, 0, 1, 0, tempMat1.data);
    SampleApplicationUtils::multiplyMatrix(tempMat1.data, rotateMat.data, tempMat2.data);
    SampleApplicationUtils::setRotationMatrix(-y, 1, 0, 0, tempMat1.data);
    SampleApplicationUtils::multiplyMatrix(tempMat1.data, tempMat2.data, rotateMat.data);
}

- (void) moveWithX:(float)x Y:(float)y
{
    SampleApplicationUtils::translatePoseMatrix(-x, -y, 0, translateMat.data);
}

- (void) scale:(float)s
{
    SampleApplicationUtils::scalePoseMatrix(s, s, s, scaleMat.data);
}

- (BOOL) enableTexture:(CZImage*)image
{
    if(image == NULL || image->data == NULL)
    {
        LOG_WARN("image is illegal\n");
        return NO;
    }
    
    TextureMap::iterator itr = textureMap.find(image);
    
    short texInd;
    if(itr == textureMap.end())
    {
        if (itr == textureMap.begin()) texInd = 0;
        else    texInd = (--itr)->second + 1;
        
        if(texInd >= 128)
        {
            LOG_ERROR("texture resources exceed!\n");
            return false;
        }
        else
        {
            //generate an OpenGL texture ID for this texture
            glGenTextures(1, &textures[texInd]);
            //bind to the new texture ID
            glBindTexture(GL_TEXTURE_2D, textures[texInd]);
            //store the texture data for OpenGL use
            if (image->colorSpace == CZImage::RGBA) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_RGBA, GL_UNSIGNED_BYTE, image->data);
            }
            else if (image->colorSpace == CZImage::RGB) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_RGB, GL_UNSIGNED_BYTE, image->data);
            }
            else if (image->colorSpace == CZImage::GRAY) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_LUMINANCE, GL_UNSIGNED_BYTE, image->data);
            }
            
            //	gluBuild2DMipmaps(GL_TEXTURE_2D, components, width, height, texFormat, GL_UNSIGNED_BYTE, bits);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            CZCheckGLError();
            textureMap[image] = texInd;
        }
    }
    else
    {
        texInd = itr->second;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textures[texInd]);
    
    return YES;

}

@end

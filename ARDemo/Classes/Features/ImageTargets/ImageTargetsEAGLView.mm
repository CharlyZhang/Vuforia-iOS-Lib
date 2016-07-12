/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

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

#import "ImageTargetsEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the Vuforia camera, which causes Vuforia to locate our EAGLView and start
//    the render thread.
// 3) Vuforia calls our renderFrameVuforia method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---

#ifdef LOAD_BUNDLE
    const char* textureFilenames[] = {
        "ARResources.bundle/models/TextureTeapotBrass.png",
        "ARResources.bundle/models/TextureTeapotBlue.png",
        "ARResources.bundle/models/TextureTeapotRed.png",
        "ARResources.bundle/models/TextureTeapotGreen.png",
        "ARResources.bundle/models/plane/texture.jpg"
    };
#else
    // Teapot texture filenames
    const char* textureFilenames[] = {
        "models/TextureTeapotBrass.png",
        "models/TextureTeapotBlue.png",
        "models/TextureTeapotRed.png",
        "models/TextureTeapotGreen.png",
        "models/plane/texture.jpg"
    };
#endif
    // Model scale factor
    const float kObjectScaleNormal = 3.0f;
    const float kObjectScaleOffTargetTracking = 12.0f;
    
    Vuforia::Matrix44F translateMat, scaleMat, rotateMat;
}


@interface ImageTargetsEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation ImageTargetsEAGLView

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }
        
        offTargetTrackingEnabled = NO;
        
        [self loadMyModel];
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

    for (int i = 0; i < kNumAugmentationTextures; ++i) {
        augmentationTexture[i] = nil;
    }
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

- (void) loadMyModel {
#ifdef LOAD_BUNDLE
    NSString *modelPath = [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"ARResources.bundle/models/plane/plane.obj"];
#else
    NSString *modelPath = [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"models/plane/plane.obj"];
#endif
    myModel = ModelFactory::createObjModel([modelPath UTF8String]);
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
        
        if (offTargetTrackingEnabled) {
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)myModel->positions.data());
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)myModel->normals.data());
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)myModel->texcoords.data());
//            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.vertices);
//            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.normals);
//            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.texCoords);
        } else {
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotTexCoords);
        }
        
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        
        // Choose the texture based on the target name
        int targetIndex = 0; // "stones"
        if (!strcmp(trackable.getName(), "chips"))
            targetIndex = 1;
        else if (!strcmp(trackable.getName(), "tarmac"))
            targetIndex = 2;
        
        glActiveTexture(GL_TEXTURE0);
        
        if (offTargetTrackingEnabled) {
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[4].textureID);
        } else {
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[targetIndex].textureID);
        }
        
        
        SampleApplicationUtils::checkGlError("before enable array!");
        
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
        
        SampleApplicationUtils::checkGlError("before active texture!");
        glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
        
        SampleApplicationUtils::checkGlError("after transform uniform!");
        
        if (offTargetTrackingEnabled) {
            for (std::vector<CZGeometry*>::iterator itr = myModel->geometries.begin(); itr != myModel->geometries.end(); itr++)
            {
                CZGeometry *pGeometry = *itr;
                glDrawArrays(GL_TRIANGLES, (GLint)pGeometry->firstIdx, (GLsizei)pGeometry->vertNum);
                
            }
//            glDrawArrays(GL_TRIANGLES, 0, (int)buildingModel.numVertices);
        } else {
            glDrawElements(GL_TRIANGLES, NUM_TEAPOT_OBJECT_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)teapotIndices);
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

@end

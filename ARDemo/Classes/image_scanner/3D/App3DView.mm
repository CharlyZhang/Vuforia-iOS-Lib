//
//  App3DView.m
//  AppleCoder-OpenGLES-00
//
//  Created by Simon Maurice on 18/03/09.
//  Copyright Simon Maurice 2009. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "App3DView.h"
#include "Application3D.h"

#define USE_DEPTH_BUFFER 1

//declare private methods, so they can be used everywhere in this file
@interface App3DView (PrivateMethods)
- (void)createFramebuffer;
- (void)deleteFramebuffer;
@end

@implementation App3DView
{
    CZ3D::Application3D app3d;
    NSArray *models;
    
    BOOL renderBufferReady;
}

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    //we don't want a transparent surface
    eaglLayer.opaque = TRUE;
    
    //here we configure the properties of our canvas, most important is the color depth RGBA8 !
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];
    
    //create an OpenGL ES 2 context
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //if this failed or we cannot set the context for some reason, quit
    if (!context || ![EAGLContext setCurrentContext:context]) {
        NSLog(@"Could not create context!");
       // [self release];
        return nil;
    }

    UIPanGestureRecognizer *rot = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    [rot setMinimumNumberOfTouches:1];
    [rot setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:rot];
    
    UIPanGestureRecognizer *mov = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [mov setMinimumNumberOfTouches:2];
    [mov setMaximumNumberOfTouches:2];
    [self addGestureRecognizer:mov];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.numberOfTapsRequired = 2;
    tap.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:tap];
    
    NSString *configPath = [[[NSBundle mainBundle]bundlePath]stringByAppendingString:@"/ARResources.bundle/scene_violin.cfg"];
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    app3d.init([[[[NSBundle mainBundle]bundlePath] stringByAppendingString:@"/ARResources.bundle/glsl/"] UTF8String],[configPath UTF8String]);
    app3d.setDocDirectory([docPath UTF8String]);
    app3d.setBackgroundColor(1, 1, 1, 1);
    //app3d.loadObjModel([model3 UTF8String]);
    
    renderBufferReady = NO;
    return self;
}// We have to implement this method


+ (Class)layerClass
{
    return [CAEAGLLayer class];
}
//our App3DView is the view in our MainWindow which will be automatically loaded to be displayed.
//when the App3DView gets loaded, it will be initialized by calling this method.


//on iOS, all rendering goes into a renderbuffer,
//which is then copied to the window by "presenting" it.
//here we create it!
- (void)createFramebuffer
{
    // Create the framebuffer and bind it so that future OpenGL ES framebuffer commands are directed to it.
    glGenFramebuffers(1, &viewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    // Create a color renderbuffer, allocate storage for it, and attach it to the framebuffer.
    glGenRenderbuffers(1, &viewRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    // Create the color renderbuffer and call the rendering context to allocate the storage on our Core Animation layer.
    // The width, height, and format of the renderbuffer storage are derived from the bounds and properties of the CAEAGLLayer object
    // at the moment the renderbufferStorage:fromDrawable: method is called.
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
    // Retrieve the height and width of the color renderbuffer.
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    app3d.setRenderBufferSize(backingWidth, backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        // Perform similar steps to create and attach a depth renderbuffer.
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    }
    
    glGenFramebuffers(1, &msaaFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
    glGenRenderbuffers(1, &msaaRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, backingWidth, backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaRenderbuffer);
    
    if (USE_DEPTH_BUFFER) {
        // Perform similar steps to create and attach a depth renderbuffer.
        glGenRenderbuffers(1, &msaaDepthbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, msaaDepthbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, msaaDepthbuffer);
    }
    
    // Test the framebuffer for completeness.
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return ;
    }
    
    renderBufferReady = YES;
}

//deleting the framebuffer and all the buffers it contains
- (void)deleteFramebuffer
{
    //we need a valid and current context to access any OpenGL methods
    glDeleteFramebuffers(1, &viewFramebuffer);
    glDeleteFramebuffers(1, &msaaFramebuffer);
    viewFramebuffer = 0;
    msaaFramebuffer = 0;
    glDeleteRenderbuffers(1, &viewRenderbuffer);
    glDeleteRenderbuffers(1, &msaaRenderbuffer);
    viewRenderbuffer = 0;
    msaaRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        glDeleteRenderbuffers(1, &msaaDepthbuffer);
        depthRenderbuffer = 0;
        msaaDepthbuffer = 0;
    }
    
    renderBufferReady = NO;
}


//this is where all the magic happens!
- (void)drawFrame
{
    if(!renderBufferReady) return;
    
    //we need a context for rendering
    if (context != nil)
    {
        //make it the current context for rendering
        [EAGLContext setCurrentContext:context];
        
        //if our framebuffers have not been created yet, do that now!
        glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderbuffer);
        app3d.frame();
        //we need a lesson to be able to render something
        //perform the actual drawing!
        
        //finally, get the color buffer we rendered to, and pass it to iOS
        //so it can display our awesome results!
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, viewFramebuffer);
        glResolveMultisampleFramebufferAPPLE();
        
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
        // Assuming you allocated a color renderbuffer to point at a Core Animation layer, you present its contents by making it the current renderbuffer
        // and calling the presentRenderbuffer: method on your rendering context.
        [context presentRenderbuffer:GL_RENDERBUFFER];
        CZCheckGLError();
    }
    else
        NSLog(@"Context not set!");
}

//our render loop just tells the iOS device that we want to keep refreshing our view all the time
- (void)startRenderLoop
{
    /* [EAGLContext setCurrentContext:context];
     [self deleteFramebuffer];
     [self createFramebuffer];*/
    
    
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawFrame) userInfo:nil repeats:YES];
}
    

//we have to be able to stop the render loop
- (void)stopRenderLoop
{
    [animationTimer invalidate];
    
}

- (void)rotateWithX:(float)x Y:(float)y
{
    app3d.rotate(x, y);
    [self drawFrame];
}

- (void) moveWithX:(float)x Y:(float)y
{
    app3d.translate(x, y);
    [self drawFrame];
}

- (void) scale:(float)s
{
    app3d.scale(s);
    [self drawFrame];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    CGFloat r,g,b,a;
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    app3d.setBackgroundColor(r, g, b, a);
    [self drawFrame];
}

- (void) reset
{
    app3d.reset();
    [self drawFrame];
}

// for debug
- (void) loadModel:(NSUInteger) modelIdx
{
    if (modelIdx > 3) {
        NSLog(@"modelIdx is out of range");
        return;
    }
    app3d.loadObjModel("model1",[[models objectAtIndex:modelIdx] UTF8String]);
    [self drawFrame];
}

- (void) setCameraPositionWithX:(float)x Y:(float)y Z:(float) z
{
    app3d.setCameraPosition(x, y, z);
    [self drawFrame];
}
- (void) setLigthDirectionWithX:(float)x Y:(float)y Z:(float) z
{
    app3d.setLigthDirection(x, y, z);
    [self drawFrame];
}
- (void) setAmbientColorWithX:(unsigned char)x Y:(unsigned char)y Z:(unsigned char) z
{
    app3d.setAmbientColor(x, y, z);
    [self drawFrame];
}
- (void) setDiffuseColorWithX:(unsigned char)x Y:(unsigned char)y Z:(unsigned char) z
{
    app3d.setDiffuseColor(x, y, z);
    [self drawFrame];
}

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    [self deleteFramebuffer];
    [self createFramebuffer];
    //[self drawFrame];
}

//cleanup our view
- (void)dealloc
{
    [self deleteFramebuffer];
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */


-(void)rotate:(id)sender {
    
    static CGPoint lastPoint;
    
    CGPoint point = [(UIPanGestureRecognizer*)sender translationInView:self];
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        [self rotateWithX:(point.x - lastPoint.x)/2.f Y: (-point.y + lastPoint.y)/2.f];
    }
    
    lastPoint = point;
}

-(void)move:(id)sender {
    
    static CGPoint lastPoint;
    
    CGPoint point = [(UIPanGestureRecognizer*)sender translationInView:self];
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        [self moveWithX:(-point.x + lastPoint.x)/5 Y:(point.y - lastPoint.y)/5];
    }
    
    lastPoint = point;
}

- (void)pinch:(UIPinchGestureRecognizer*)pinch {
    if (pinch.state == UIGestureRecognizerStateChanged) {
        [self scale:pinch.scale];
        pinch.scale = 1;
    }
}

- (void)tap:(UITapGestureRecognizer*)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        app3d.reset();
        [self drawFrame];
    }
}

- (void) load:(NSString*) modelName
{
    [EAGLContext setCurrentContext:context];
    app3d.loadObjModel("model1",[modelName UTF8String]);
}

- (void)unloadModel
{
    [EAGLContext setCurrentContext:context];
}
@end


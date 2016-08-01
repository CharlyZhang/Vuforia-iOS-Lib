//
//  ARScannerEAGLView.h
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Vuforia/UIGLViewProtocol.h>
#import "SampleApplicationSession.h"

#define NOTIFICATION_IMG_TARGET_FOUND @"kImageTargetFound"
#define KEY_IMAGE_TARGET_NAME @"ImageTargetName"

@protocol ARGLResourceHandler;

@interface ARScannerEAGLView : UIView <UIGLViewProtocol, ARGLResourceHandler>

/*/
 @{@"targetName" : @"modelPath"}
 /*/
- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void) setOffTargetTrackingMode:(BOOL) enabled;

@end

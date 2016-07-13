//
//  AREAGLView.h
//  ARDemo
//
//  Created by CharlyZhang on 16/7/13.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Vuforia/UIGLViewProtocol.h>
#import "SampleApplicationSession.h"
#import "SampleGLResourceHandler.h"

@interface AREAGLView : UIView <UIGLViewProtocol, SampleGLResourceHandler> 

/*/
 @{@"targetName" : @"modelPath"}
/*/
- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app modelsConfig:(NSDictionary*)paths;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void) setOffTargetTrackingMode:(BOOL) enabled;

- (void) rotateWithX:(float)x Y:(float)y;
- (void) moveWithX:(float)x Y:(float)y;
- (void) scale:(float)s;
@end

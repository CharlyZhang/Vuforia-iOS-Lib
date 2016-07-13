//
//  AppDelegate.h
//  TestARLib
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ARViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) id<ARGLResourceHandler> glResourceHandler;

@end


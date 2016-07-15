//
//  AppDelegate.m
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSDictionary *config = @{AR_CONFIG_INIT_FLAG : @"Your Vuforia License Key",
                             
                             AR_CONFIG_DATA_SETS : @[
                                                      @{
                                                          AR_CONFIG_DATASET_NAME : @"myData",
                                                          AR_CONFIG_DATASET_PATH : @"datasets/ImageTargets/VuforiaTestDevice.xml"
                                                      },
                                                      @{
                                                          AR_CONFIG_DATASET_NAME : @"chips",
                                                          AR_CONFIG_DATASET_PATH : @"datasets/ImageTargets/StonesAndChips.xml"
                                                      }
                                     ],
                             AR_CONFIG_MODEL  : @[
                                     @{
                                         AR_CONFIG_TARGET_NAME  :   @"img20120929",
                                         AR_CONFIG_MODEL_PATH   :   @"models/plane/plane.obj"
                                     },
                                     @{
                                         AR_CONFIG_TARGET_NAME  :   @"SunStructure",
                                         AR_CONFIG_MODEL_PATH   :   @"models/南禅寺1/ww.obj"
                                    }
                                     ]};
    self.window.rootViewController = [[ARViewController alloc]initWithParam:config];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (self.glResourceHandler) {
        // Delete OpenGL resources (e.g. framebuffer) of the SampleApp AR View
        [self.glResourceHandler freeOpenGLESResources];
        [self.glResourceHandler finishOpenGLESCommands];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

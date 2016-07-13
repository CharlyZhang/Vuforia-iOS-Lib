//
//  ARViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AR_CONFIG_INIT_FLAG    @"initFlag"
#define AR_CONFIG_DATA_SETS    @"dataSets"
#define AR_CONFIG_MODEL        @"models"

@protocol ARGLResourceHandler

@required
- (void) freeOpenGLESResources;
- (void) finishOpenGLESCommands;
@end

@interface ARViewController : UIViewController

/*/
 @"initFlag" : @"...."
 @"dataSets": @{@"name1":@"path1",@"name2":@"path2"...}
 @"models" : @{@"targetName" : @"modelPath"}
/*/

- (instancetype)initWithParam:(NSDictionary*)config;

@property (nonatomic) BOOL extendedTrackingEnabled;     
@property (nonatomic) BOOL continuousAutofocusEnabled;
@property (nonatomic) BOOL flashEnabled;
@property (nonatomic) BOOL frontCameraEnabled;
@property (nonatomic, strong) NSString *activeDataSetName;

@end

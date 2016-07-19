//
//  ARViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AR_CONFIG_INIT_FLAG    @"InitFlag"
#define AR_CONFIG_DATA_SETS    @"DataSets"
#define AR_CONFIG_MODEL        @"Models"
#define AR_CONFIG_DATASET_NAME  @"DataSetName"
#define AR_CONFIG_DATASET_PATH  @"DataSetPath"
#define AR_CONFIG_TARGET_NAME   @"TargetName"
#define AR_CONFIG_MODEL_PATH    @"ModelPath"
@class ARViewController;

@protocol ARGLResourceHandler

@required
- (void) freeOpenGLESResources;
- (void) finishOpenGLESCommands;
@end

@protocol ARViewControllerDelegate

@required

- (void)didDismissARviewController:(ARViewController *) arviewctrl;

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
@property (nonatomic, weak) id<ARViewControllerDelegate> delegate;

@end

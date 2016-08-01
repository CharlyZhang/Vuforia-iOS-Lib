//
//  ARScannerViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AR_CONFIG_INIT_FLAG    @"InitFlag"
#define AR_CONFIG_DATA_SETS    @"DataSets"
#define AR_CONFIG_ACTION        @"Actions"
#define AR_CONFIG_DATASET_NAME  @"DataSetName"
#define AR_CONFIG_DATASET_PATH  @"DataSetPath"
#define AR_CONFIG_ACTION_TYPE   @"ActionType"
#define AR_CONFIG_ACTION_RES_PATH   @"ActionResPath"

///
#define KEY_ACTION_TYPE_3D      @"kActionType3D"
#define KEY_ACTION_TYPE_WEB     @"kActionTypeWeb"
#define KEY_ACTION_TYPE_QUIZ    @"kActionTypeQuiz"

#define MAX_SIMUTANEOUS_REC_NUM 1

@class ARScannerViewController;

@protocol ARGLResourceHandler

@required
- (void) freeOpenGLESResources;
- (void) finishOpenGLESCommands;
@end

@protocol ARScannerViewControllerDelegate

@required

- (void)didDismissARScannerViewController:(ARScannerViewController *) arviewctrl Action:(NSDictionary*)actionDetail;

@end

@interface ARScannerViewController : UIViewController


- (instancetype)initWithParam:(NSDictionary*)config;

@property (nonatomic) BOOL extendedTrackingEnabled;
@property (nonatomic) BOOL continuousAutofocusEnabled;
@property (nonatomic) BOOL flashEnabled;
@property (nonatomic) BOOL frontCameraEnabled;
@property (nonatomic, strong) NSString *activeDataSetName;
@property (nonatomic, weak) id<ARScannerViewControllerDelegate> delegate;

@end

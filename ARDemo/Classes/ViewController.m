//
//  ViewController.m
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "ViewController.h"
#import "ARViewController.h"

@interface ViewController () <ARViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testClick:(UIButton *)sender {
    // Override point for customization after application launch.
    NSDictionary *config = @{AR_CONFIG_INIT_FLAG : @"Your Vuforia License Key",
                             
                             AR_CONFIG_DATA_SETS : @[
                                     @{
                                         AR_CONFIG_DATASET_NAME : @"myData",
                                         AR_CONFIG_DATASET_PATH : [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"datasets/ImageTargets/VuforiaTestDevice.xml"]
                                         },
                                     @{
                                         AR_CONFIG_DATASET_NAME : @"chips",
                                         AR_CONFIG_DATASET_PATH : [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"datasets/ImageTargets/StonesAndChips.xml"]
                                         }
                                     ],
                             AR_CONFIG_MODEL  : @[
                                     @{
                                         AR_CONFIG_TARGET_NAME  :   @"img20120929",
                                         AR_CONFIG_MODEL_PATH   :   [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"models/plane/plane.obj"]
                                         },
                                     @{
                                         AR_CONFIG_TARGET_NAME  :   @"SunStructure",
                                         AR_CONFIG_MODEL_PATH   :   [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"models/南禅寺1/ww.obj"]
                                         }
                                     ]};
    ARViewController *arViewCtrl = [[ARViewController alloc]initWithParam:config];
    arViewCtrl.delegate = self;
    [self presentViewController:arViewCtrl animated:YES completion:nil];
}

- (void) didDismissARviewController:(ARViewController *)arviewctrl
{
    [self dismissViewControllerAnimated:NO completion:nil];
    arviewctrl = nil;
}

@end

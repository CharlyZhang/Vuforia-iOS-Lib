//
//  ViewController.m
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "ViewController.h"
#import "ARScannerViewController.h"
#import "Obj3DViewController.h"
#import "WebViewController.h"

@interface ViewController () <ARScannerViewControllerDelegate, Obj3DViewControllerDelegate, WebViewControllerDelegate>
{
    ARScannerViewController *arScannerViewCtrl;
}

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
//    Obj3DViewController *obj3DViewCtrl =  [[Obj3DViewController alloc]initWithModelPath:[[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"models/Orchid/huapeng.obj"]];
//    obj3DViewCtrl.delegate = self;
//    [self presentViewController:obj3DViewCtrl animated:YES completion:nil];
    
//    WebViewController *webViewCtrl = [[WebViewController alloc] initWithUrl:@"https://weibo.com"];
//    [self presentViewController:webViewCtrl animated:NO completion:nil];
//    return;
    
    // Override point for customization after application launch.
    NSDictionary *config = @{AR_CONFIG_INIT_FLAG : @"Your License Key",
                             
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
                             AR_CONFIG_ACTION  : @{
                                     @"img20120929"  :@{
                                             AR_CONFIG_ACTION_TYPE      : KEY_ACTION_TYPE_3D,
                                             AR_CONFIG_ACTION_RES_PATH  : [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"models/plane/plane.obj"]
                                         },
                                     @"SunStructure"  :@{
                                             AR_CONFIG_ACTION_TYPE      : KEY_ACTION_TYPE_WEB,
                                             AR_CONFIG_ACTION_RES_PATH  : @"http://www.weibo.com"
                                        }
                                     }
                             };
    
    arScannerViewCtrl = [[ARScannerViewController alloc]initWithParam:config];
    arScannerViewCtrl.delegate = self;
    [self presentViewController:arScannerViewCtrl animated:YES completion:nil];
}

- (void) didDismissARScannerViewController:(ARScannerViewController *)arviewctrl Action:(NSDictionary *)actionDetail
{
    if(actionDetail == nil)
        [self dismissViewControllerAnimated:NO completion:nil];
    else {
        NSString *actionType = [actionDetail objectForKey:AR_CONFIG_ACTION_TYPE];
        NSString *resPath = [actionDetail objectForKey:AR_CONFIG_ACTION_RES_PATH];
        
        if ([actionType isEqualToString:KEY_ACTION_TYPE_3D]) {
            Obj3DViewController *obj3DViewCtrl =  [[Obj3DViewController alloc]initWithModelPath:resPath];
            obj3DViewCtrl.delegate = self;
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:obj3DViewCtrl animated:NO completion:nil];
            }];
        }
        else if([actionType isEqualToString:KEY_ACTION_TYPE_WEB]) {
            WebViewController *webViewCtrl = [[WebViewController alloc] initWithUrl:resPath];
            webViewCtrl.delegate = self;
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:webViewCtrl animated:NO completion:nil];
            }];
        }
        else if([actionType isEqualToString:KEY_ACTION_TYPE_HTML]) {
            WebViewController *webViewCtrl = [[WebViewController alloc] initWithPath:resPath];
            webViewCtrl.delegate = self;
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:webViewCtrl animated:NO completion:nil];
            }];
        }
        else if([actionType isEqualToString:KEY_ACTION_TYPE_QUIZ]) {
            
        }
        else {
            
        }
    }
//    [arviewctrl release];
}

- (void) didDismissObj3DViewController:(Obj3DViewController *)obj3dViewCtrl
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) didDismissWebViewController:(WebViewController *)webViewCtrl {
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end

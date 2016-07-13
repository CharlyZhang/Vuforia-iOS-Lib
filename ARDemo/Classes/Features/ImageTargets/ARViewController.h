//
//  ARViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ARViewController : UIViewController

/*/
 @"dataSets": @{@"name1":@"path1",@"name2":@"path2"...};
/*/

- (instancetype)initWithParam:(NSDictionary*)config;

@property (nonatomic) BOOL extendedTrackingEnabled;     
@property (nonatomic) BOOL continuousAutofocusEnabled;
@property (nonatomic) BOOL flashEnabled;
@property (nonatomic) BOOL frontCameraEnabled;
@property (nonatomic, strong) NSString *activeDataSetName;

@end

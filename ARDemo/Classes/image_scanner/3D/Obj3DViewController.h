//
//  Obj3DViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Obj3DViewController;

@protocol Obj3DViewControllerDelegate <NSObject>

@required
- (void)didDismissObj3DViewController:(Obj3DViewController*)obj3dViewCtrl;

@end

@interface Obj3DViewController : UIViewController

@property (nonatomic,weak) id<Obj3DViewControllerDelegate> delegate;

- (instancetype) initWithModelPath:(NSString*)path;

@end

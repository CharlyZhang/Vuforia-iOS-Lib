//
//  WebViewController.h
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebViewController;

@protocol WebViewControllerDelegate <NSObject>

@required
- (void)didDismissWebViewController:(WebViewController*)webViewCtrl;

@end


@interface WebViewController : UIViewController

- (instancetype) initWithUrl:(NSString*) url;
- (instancetype) initWithPath:(NSString*) path;

@property (weak, nonatomic) id<WebViewControllerDelegate> delegate;

@end

//
//  Obj3DViewController.m
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "Obj3DViewController.h"
#import "MBProgressHUD.h"
#import "App3DView.h"

@interface Obj3DViewController ()
{
    MBProgressHUD       *hud;
    App3DView           *app3Dview;
}

@property (nonatomic, strong) NSString* modelPath;

@end

@implementation Obj3DViewController

- (instancetype) initWithModelPath:(NSString*)path
{
    if(self = [super init]) {
        self.modelPath = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // hud
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText = @"loading...";
    
    // app3dView
    app3Dview = [[App3DView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:app3Dview];
    
    // 添加按键
    NSString * resourceFilePath = [[NSBundle mainBundle] resourcePath];
    NSString * closeIconButtonPath = [resourceFilePath stringByAppendingPathComponent:@"icon_close.png"];
    UIImage * closeIconImg = [UIImage imageWithContentsOfFile:closeIconButtonPath];
    CGSize closeIconButtonSize = closeIconImg.size;
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setFrame:CGRectMake(CGRectGetWidth(app3Dview.bounds) - closeIconButtonSize.width - 10, 10.0, closeIconButtonSize.width, closeIconButtonSize.height)];
    [closeButton setImage:closeIconImg forState:UIControlStateNormal];
    [app3Dview addSubview:closeButton];
    [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    
    [app3Dview setBackgroundColor:[UIColor whiteColor]];
    [self showModel:self.modelPath];
}

- (void) showModel:(NSString*) path
{
    __block App3DView *blockView = app3Dview;
    [hud showAnimated:YES whileExecutingBlock:^{
        [blockView load:path];
    } completionBlock:^ {
        [blockView drawFrame];
    }];
}

- (void)closeView
{
    [self.delegate didDismissObj3DViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

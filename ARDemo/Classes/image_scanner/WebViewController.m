//
//  WebViewController.m
//  ARDemo
//
//  Created by CharlyZhang on 16/8/1.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "WebViewController.h"

#define INDICATOR_VIEW_SIZE 32.f

@interface WebViewController ()<UIWebViewDelegate>
{
    NSURL *url;
}

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIView *indicatorView;
@property (strong, nonatomic) UIActivityIndicatorView *activeIndicatorView;
@property (strong, nonatomic) UIButton *closeButton;

@end

@implementation WebViewController

- (instancetype)initWithUrl:(NSString*) url_ {
    if(self = [super init]) {
        url = [NSURL URLWithString: url_];
    }
    
    return self;
}

- (instancetype) initWithPath: (NSString*) path_ {
    if(self = [super init]) {
        url = [NSURL fileURLWithPath:path_];
    }
    
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.webView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.indicatorView];
    [self.indicatorView addSubview:self.activeIndicatorView];
    
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void) viewWillAppear:(BOOL)animated {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    [self.webView setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.indicatorView setFrame: CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.activeIndicatorView setCenter:self.indicatorView.center];
    CGSize closeIconButtonSize = self.closeButton.bounds.size;
    [self.closeButton setFrame:CGRectMake(screenSize.width - closeIconButtonSize.width - 10, 10.0, closeIconButtonSize.width, closeIconButtonSize.height)];
}

- (void) viewDidAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate
{
    //    NSLog(@"shouldAutorotate");
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //    NSLog(@"supportedInterfaceOrientations");
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //    NSLog(@"preferredInterfaceOrientationForPresentation");
    return UIInterfaceOrientationLandscapeLeft;
}


#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.indicatorView setAlpha:0.5f];
    [self.activeIndicatorView startAnimating] ;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activeIndicatorView stopAnimating];
    [self.indicatorView setAlpha:0.0f];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.webView.isLoading) return;
    if (error.code == NSURLErrorCancelled) return;
    [self.activeIndicatorView stopAnimating];
    [self.indicatorView setAlpha:0.0f];
    
    UIAlertView *alterview = [[UIAlertView alloc] initWithTitle:@"网页载入错误" message:[error localizedDescription]  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alterview show];
}

#pragma mark - Private

- (void) closeView {
    [self.delegate didDismissWebViewController:self];
}

#pragma mark - Properties

- (UIWebView*) webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        _webView.scrollView.scrollEnabled = NO;
    }
    return _webView;
}

- (UIView*) indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        [_indicatorView setBackgroundColor:[UIColor blackColor]];
        [_indicatorView setAlpha:0.0f];
    }
    return _indicatorView;
}

- (UIActivityIndicatorView*) activeIndicatorView {
    if (!_activeIndicatorView) {
        _activeIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, INDICATOR_VIEW_SIZE, INDICATOR_VIEW_SIZE)];
    }
    return _activeIndicatorView;
}

- (UIButton*) closeButton {
    if (!_closeButton) {
        NSString * resourceFilePath = [[NSBundle mainBundle] resourcePath];
        NSString * closeIconButtonPath = [resourceFilePath stringByAppendingPathComponent:@"icon_close.png"];
        UIImage * closeIconImg = [UIImage imageWithContentsOfFile:closeIconButtonPath];
        CGSize closeIconButtonSize = closeIconImg.size;
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        [_closeButton setFrame:CGRectMake(screenSize.width - closeIconButtonSize.width - 10, 10.0, closeIconButtonSize.width, closeIconButtonSize.height)];
        [_closeButton setImage:closeIconImg forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}
@end

//
//  ARViewController.m
//  ARDemo
//
//  Created by CharlyZhang on 16/7/12.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#import "ARViewController.h"
#import "SampleApplicationSession.h"
#import "AREAGLView.h"
#import "AppDelegate.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/DataSet.h>
#include <map>
#include <string>

#define CLOSE_BUTTON_OFFSET 10

using namespace std;

typedef map<string, Vuforia::DataSet*> DataSetMap;
@interface ARViewController ()  <SampleApplicationControl>
{
    Vuforia::DataSet* dataSetCurrent;
    string curDataSetName;
    DataSetMap datasets;
    UIButton *closeButton;
    CGSize closeIconButtonSize;
}

@property (nonatomic, strong) AREAGLView* eaglView;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;
@property (nonatomic, strong) SampleApplicationSession * vapp;
@property (nonatomic, strong) NSDictionary *configurations;

@end

@implementation ARViewController

@synthesize tapGestureRecognizer, vapp, eaglView;
@synthesize extendedTrackingEnabled, continuousAutofocusEnabled, flashEnabled, frontCameraEnabled;
@synthesize configurations;

- (instancetype)initWithParam:(NSDictionary*)config
{
    if (self = [super init]) {
        configurations = config;
    }
    
    return self;
}

- (void)loadView
{
    // Custom initialization
    self.title = @"Image Targets";
   
    extendedTrackingEnabled = NO;
    continuousAutofocusEnabled = YES;
    flashEnabled = NO;
    frontCameraEnabled = NO;
    
    vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    eaglView = [[AREAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    [eaglView setUpApp3D];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotateInterfaceOrientation:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    NSArray *modelsConfig = [configurations objectForKey:AR_CONFIG_MODEL];
    [eaglView loadModels:modelsConfig];
    
    // initialize AR
    NSString *initFlag = [configurations objectForKey:AR_CONFIG_INIT_FLAG];
    NSLog(@"interfaceOrientation %ld",self.interfaceOrientation);
    [vapp initAR:Vuforia::GL_20 orientation:self.interfaceOrientation flags:initFlag];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view addGestureRecognizer:tapGestureRecognizer];

    [self createInteractionGuesturesForView:self.view];
    
    NSString * closeIconButtonPath = [[[NSBundle mainBundle] resourcePath ]stringByAppendingString:@"/ARResources.bundle/icon_close.png"];
    UIImage *closeIconImg = [UIImage imageWithContentsOfFile:closeIconButtonPath];
    closeIconButtonSize = closeIconImg.size;
    closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - closeIconButtonSize.width - CLOSE_BUTTON_OFFSET, CLOSE_BUTTON_OFFSET, closeIconButtonSize.width, closeIconButtonSize.height)];
    [closeButton setImage:closeIconImg forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(exitAR) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    NSLog(@"self.navigationController.navigationBarHidden: %s", self.navigationController.navigationBarHidden ? "Yes" : "No");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [vapp stopAR:nil];
    
    // Be a good OpenGL ES citizen: now that Vuforia is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [self finishOpenGLESCommands];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = nil;
    
    [super viewWillDisappear:animated];
}

- (BOOL) shouldAutorotate
{
//    NSLog(@"shouldAutorotate");
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
//    NSLog(@"supportedInterfaceOrientations");
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
//    NSLog(@"preferredInterfaceOrientationForPresentation");
    return UIInterfaceOrientationPortrait;
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc
{
    NSLog(@"ARViewController dealloc!");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    datasets.clear();
}

#pragma mark - Property

- (NSString*) activeDataSetName
{
    ///! it dosen't mean the data set is loaded successfully
    return [NSString stringWithUTF8String:curDataSetName.c_str()];
}

- (void) setActiveDataSetName:(NSString *)activeDataSetName
{
    string name([activeDataSetName UTF8String]);
    DataSetMap::iterator itr = datasets.find(name);
    if(itr == datasets.end())
    {
        NSLog(@"dataset(%@) does not exist!",activeDataSetName);
        return ;
    }
    
    NSLog(@"active dataset (%@)",activeDataSetName);
    curDataSetName = name;
}

#pragma mark - Public


#pragma mark - SampleApplicationControl

// Initialize the application trackers
- (bool) doInitTrackers {
    // Initialize the object tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

// load the data associated to the trackers
- (bool) doLoadTrackersData {
    datasets.clear();
    NSArray *configDS = [configurations objectForKey:AR_CONFIG_DATA_SETS];
    
    curDataSetName = "";
    for(NSDictionary *DS in configDS)
    {
        Vuforia::DataSet* ds = [self loadObjectTrackerDataSet:DS[AR_CONFIG_DATASET_PATH]];
        if(ds == NULL)
        {
            NSLog(@"Failed to load datasets(%@)",DS[AR_CONFIG_DATASET_NAME]);
            return NO;
        }
        string n([DS[AR_CONFIG_DATASET_NAME] UTF8String]);
        datasets[n] = ds;
        if(curDataSetName == "") curDataSetName = n;
    }
    
    if (! [self activateDataSet:datasets[curDataSetName]]) {
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    
#ifdef DEBUG
    self.activeDataSetName = @"myData";
#endif
    return YES;
}

// start the application trackers
- (bool) doStartTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

// callback called when the initailization of the AR is done
- (void) onInitARDone:(NSError *)initError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLoadingAnimation];
    });
    if (initError == nil) {
        NSError * error = nil;
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
         Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, MAX_SIMUTANEOUS_REC_NUM);
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            alert.tag = 0;
            [alert show];
        });
    }
}

- (bool) doStopTrackers {
    // Stop the tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

- (bool) doUnloadTrackersData {
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    for(DataSetMap::iterator itr = datasets.begin(); itr != datasets.end(); itr ++)
    {
        if(!objectTracker->destroyDataSet(itr->second))
        {
            NSLog(@"Failed to destroy data set %s.",itr->first.c_str());
        }
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

- (void) onVuforiaUpdate: (Vuforia::State *) state {
    if(datasets[curDataSetName] != dataSetCurrent)
    {
        [self activateDataSet:datasets[curDataSetName]];
    }
}

- (bool) doDeinitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return YES;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissARViewController" object:nil];
}

- (void)dismissARViewController
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        if(buttonIndex == 1)
        {
            [eaglView freeApp3D];
            [self.delegate didDismissARviewController:self];
        }
    }
}

#pragma mark - loading animation

- (void) showLoadingAnimation {
    CGRect indicatorBounds;
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
                                 largerBoundsSize / 2 - 12, 24, 24);
//    
//    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
//        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
//                                     largerBoundsSize / 2 - 12, 24, 24);
//    }
//    else {
//        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
//                                     smallerBoundsSize / 2 - 12, 24, 24);
//    }
    
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                 initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}

#pragma mark - Private

- (void) exitAR {
    [eaglView freeApp3D];
    [self.delegate didDismissARviewController:self];
}

- (void) didRotateInterfaceOrientation:(NSNotification*) notification
{
    UIDeviceOrientation curOrientation = [[UIDevice currentDevice]orientation];
    CGRect newRect = closeButton.frame;
    switch (curOrientation) {
        case UIDeviceOrientationPortrait:
            newRect = CGRectMake(CGRectGetWidth(self.view.bounds) - closeIconButtonSize.width - CLOSE_BUTTON_OFFSET, CLOSE_BUTTON_OFFSET, closeIconButtonSize.width, closeIconButtonSize.height);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            newRect = CGRectMake(CLOSE_BUTTON_OFFSET, CGRectGetHeight(self.view.bounds) - closeIconButtonSize.height - CLOSE_BUTTON_OFFSET, closeIconButtonSize.width, closeIconButtonSize.height);
            break;
        case UIDeviceOrientationLandscapeLeft:
            newRect = CGRectMake(CGRectGetWidth(self.view.bounds) - closeIconButtonSize.width - CLOSE_BUTTON_OFFSET, CGRectGetHeight(self.view.bounds) - closeIconButtonSize.height - CLOSE_BUTTON_OFFSET, closeIconButtonSize.width, closeIconButtonSize.height);
            break;
        case UIDeviceOrientationLandscapeRight:
            newRect = CGRectMake(CLOSE_BUTTON_OFFSET, CLOSE_BUTTON_OFFSET, closeIconButtonSize.width, closeIconButtonSize.height);
            break;
        default:
            break;
    }
    
    closeButton.frame = newRect;
}

- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= [UIScreen mainScreen].nativeScale;
        viewFrame.size.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewFrame;
}

- (void) createInteractionGuesturesForView:(UIView*)view {
    UIPanGestureRecognizer *rot = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    [rot setMinimumNumberOfTouches:1];
    [rot setMaximumNumberOfTouches:1];
    [view addGestureRecognizer:rot];
    
    UIPanGestureRecognizer *mov = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [mov setMinimumNumberOfTouches:2];
    [mov setMaximumNumberOfTouches:2];
    [view addGestureRecognizer:mov];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    [view addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *doubletap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exit:)];
    doubletap.numberOfTouchesRequired = 1;
    doubletap.numberOfTapsRequired = 2;
    [view addGestureRecognizer:doubletap];
    
    UITapGestureRecognizer *double2tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reset:)];
    double2tap.numberOfTouchesRequired = 2;
    double2tap.numberOfTapsRequired = 2;
    [view addGestureRecognizer:double2tap];
    
}

-(void)rotate:(id)sender {
    NSLog(@"rotate");
    
    static CGPoint lastPoint;
    
    CGPoint point = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        [eaglView rotateWithX:point.x - lastPoint.x Y:-point.y + lastPoint.y];
    }
    
    lastPoint = point;
}

-(void)move:(id)sender {
    NSLog(@"move");
    
    static CGPoint lastPoint;
    
    CGPoint point = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        [eaglView moveWithX:(-point.x + lastPoint.x)/5 Y:(point.y - lastPoint.y)/5];
    }
    
    lastPoint = point;
}

- (void)scale:(UIPinchGestureRecognizer*)pinch {
    NSLog(@"scale");
    if (pinch.state == UIGestureRecognizerStateChanged) {
        [eaglView scale:pinch.scale];
        pinch.scale = 1;
    }
}

- (void)reset:(UITapGestureRecognizer*) tap{
    if (tap.state == UIGestureRecognizerStateEnded) {
        [eaglView reset];
    }
}

- (void) exit:(UITapGestureRecognizer*) tap
{
    if (tap.state == UIGestureRecognizerStateEnded) {
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"退出"
                                                            message:@"您确定退出该AR资源？"
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定",nil];
            alert.tag = 1;
            [alert show];
        });
    }
}

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    // on resume, we reset the flash
    Vuforia::CameraDevice::getInstance().setFlashTorchMode(false);
    flashEnabled = NO;
}

- (void)autofocus:(UITapGestureRecognizer *)sender
{
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus
{
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}

- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}

- (BOOL)activateDataSet:(Vuforia::DataSet *)theDataSet
{
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingEnabled];
    }
    
    return success;
}

- (BOOL)deactivateDataSet:(Vuforia::DataSet *)theDataSet
{
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}

- (BOOL) setExtendedTrackingForDataSet:(Vuforia::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

// Load the image tracker data set
- (Vuforia::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_ABSOLUTE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}

@end

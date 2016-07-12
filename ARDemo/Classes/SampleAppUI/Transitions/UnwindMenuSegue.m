/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "UnwindMenuSegue.h"
#import "SampleAppMenuViewController.h"


@implementation UnwindMenuSegue

static const CGFloat kTransitionDuration = 0.3;

- (void)perform {
    SampleAppMenuViewController *menuViewController = (SampleAppMenuViewController*)self.sourceViewController;
    UIViewController *ARViewController = menuViewController.presentingViewController;
    
    BOOL iOS8 = [[UIDevice currentDevice].systemVersion floatValue] >= 8.0;
    if (!iOS8) {
        // iOS 7: we dimiss the menu right away as the animation of the sliding menu
        // doesn't work properly (black frames)
        [menuViewController dismissViewControllerAnimated:NO completion:nil];
    } else {
        CGRect menuTableViewFrame = menuViewController.tableView.frame;
        CGFloat menuTableWidth = menuTableViewFrame.size.width;
        
        
        CGRect menuViewStartFrame = menuViewController.view.frame;
        CGRect menuViewEndFrame = menuViewStartFrame;
        menuViewEndFrame.origin.x -= menuTableWidth;
        
        CGRect ARViewStartFrame = ARViewController.view.frame;
        CGRect ARViewEndFrame = ARViewStartFrame;
        ARViewEndFrame.origin.x = 0;
        
        [UIView animateWithDuration:kTransitionDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             // we set the final AR frame
                             [ARViewController.view setFrame:ARViewEndFrame];
                             [menuViewController.view setFrame:menuViewEndFrame];
                         }
                         completion:^(BOOL finished){
                             [menuViewController dismissViewControllerAnimated:NO completion:^{
                                 // we set the final AR frame
                                 [ARViewController.view setFrame:ARViewEndFrame];
                             }];
                         }];
        
    }
}

@end


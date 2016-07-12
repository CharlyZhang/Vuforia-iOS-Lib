/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "PresentMenuSegue.h"
#import "SampleAppMenuViewController.h"

@implementation PresentMenuSegue

static const CGFloat kTransitionDuration = 0.3;

- (void)perform {
    // we setup a presentation style that supports overlay with transparency
    [self setupPresentationStyle:self.sourceViewController destination:self.destinationViewController];
    
    UIViewController *ARViewController = self.sourceViewController;
    SampleAppMenuViewController *menuViewController = (SampleAppMenuViewController*)self.destinationViewController;
    
    CGRect ARViewStartFrame = ARViewController.view.frame;
    CGFloat menuWidthScale = [SampleAppMenuViewController getMenuWidthScale];
    CGRect scaledTableFrame = CGRectMake(0, 0, menuWidthScale * ARViewStartFrame.size.width, ARViewStartFrame.size.height);
    
    // we make sure the menu frame is correctly scaled
    [menuViewController.tableView setFrame:scaledTableFrame];
    
    UIView* menuViewSnapshot = [menuViewController.view snapshotViewAfterScreenUpdates:YES];
    
    // we add the menu view snapshot temporarily as a sibling of the AR view,
    // for the duration of the animation
    [ARViewController.view.superview insertSubview:menuViewSnapshot aboveSubview:ARViewController.view];
    
    // we get the menu table width
    CGFloat menuTableWidth = menuViewController.tableView.frame.size.width;
    
    // we shift the menu to the left by 'menuTableWidth',
    // so that it appears at the left of the AR view,
    // during the sliding animation
    CGRect menuViewStartFrame = menuViewController.view.frame;
    menuViewStartFrame.origin.x -= menuTableWidth;
    [menuViewController.view setFrame:menuViewStartFrame];
    [menuViewSnapshot setFrame:menuViewStartFrame];
    
    // we setup the menu and AR frames for the end of animation
    CGRect menuViewEndFrame = menuViewStartFrame;
    menuViewEndFrame.origin.x += menuTableWidth;
    
    CGRect ARViewEndFrame = ARViewStartFrame;
    ARViewEndFrame.origin.x += menuTableWidth;
    
    // we animate the views
    [UIView animateWithDuration:kTransitionDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [menuViewSnapshot  setFrame:menuViewEndFrame];
                         [menuViewController.view  setFrame:menuViewEndFrame];
                         [ARViewController.view setFrame:ARViewEndFrame];
                     }
                     completion:^(BOOL finished){
                         [menuViewController.view setUserInteractionEnabled:YES];
                         // we set the menu view final frame
                         [menuViewController.view setFrame:menuViewEndFrame];
                         
                         // we present the menuViewController;
                         // note that the ARViewController will still remain visible (in the background),
                         // as we are using modalPresentationStyle = UIModalPresentationOverCurrentContext;
                         [ARViewController presentViewController:menuViewController animated:NO completion:^{
                             // we remove the menu 'snapshot' view from the temp superview
                             [menuViewSnapshot removeFromSuperview];
                             
                             // we set the menu view final frame
                             [menuViewController.view setFrame:menuViewEndFrame];
                          }];
                     }];
}

// Defines presentaion style to support overlay with transparency
- (void)setupPresentationStyle:(UIViewController *)src destination:(UIViewController*)dest
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        // iOS 8 devices
        src.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        src.modalPresentationStyle = UIModalPresentationCurrentContext;
        src.providesPresentationContextTransitionStyle = YES;
        src.definesPresentationContext = YES;
        dest.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    else {
        // iOS 7 devices
        src.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        src.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
}

@end

/*===============================================================================
Copyright (c) 2015 PTC Inc. All Rights Reserved.

 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleAppSelectorViewController.h"
#import "SampleAppAboutViewController.h"


@interface SampleAppSelectorViewController ()

@property (nonatomic, copy) NSString *selectedAppName;

@property (nonatomic, strong) NSMutableDictionary *aboutPages;
@end

@implementation SampleAppSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _aboutPages = [[NSMutableDictionary alloc] init];
    _aboutPages[@"Image Targets"] = @"IT_about";
    _aboutPages[@"Cylinder Targets"] = @"CT_about";
    _aboutPages[@"Multi Targets"] = @"MT_about";
    _aboutPages[@"Object Reco"] = @"OR_about";
    _aboutPages[@"User Defined Targets"] = @"UD_about";
    _aboutPages[@"Cloud Reco"] = @"CR_about";
    _aboutPages[@"Text Reco"] = @"TR_about";
    _aboutPages[@"Frame Markers"] = @"FM_about";
    _aboutPages[@"Virtual Buttons"] = @"VB_about";
    
    // Make sure the navigation bar is visible
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    // Make sure the navigation bar is visible
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *selCell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *selLabel = [self findLabelInCell:selCell];
    self.selectedAppName = [NSString stringWithString:((selLabel != nil) ? selLabel.text : @"")];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"PresentAboutPage" sender:self];
}

- (UILabel*)findLabelInCell:(UITableViewCell *)cell
{
    for (UIView *view in [cell.contentView subviews]) {
        if ([view isKindOfClass:[UILabel class]]) {
            return ((UILabel*)view);
        }
    }
    return nil;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *dest = [segue destinationViewController];
    
    if ([dest isKindOfClass:[SampleAppAboutViewController class]]) {
        // we want the back button to always have the label "Back"
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        SampleAppAboutViewController *about = (SampleAppAboutViewController*)dest;
        about.title = self.selectedAppName;
        about.appTitle = self.selectedAppName;
        about.appAboutPageName = _aboutPages[self.selectedAppName];
    }
}

@end

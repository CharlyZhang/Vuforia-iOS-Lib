/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleAppMenuViewController.h"
#import "UnwindMenuSegue.h"

static const CGFloat ShadowOpacity = 0.6;
static const CGFloat ShadowRadiusCorner = 3.0;

@interface SampleAppMenuViewController ()
    
@end

@implementation SampleAppMenuViewController

@synthesize showingMenu, windowTapGestureRecognizer, windowTapGestureRecognizerAdded;

+ (CGFloat)getMenuWidthScale
{
    return 0.8;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add swipe-left gesture recognizer
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    swipeLeft.delegate = self;
    [self.view addGestureRecognizer:swipeLeft];
    
    showingMenu = YES;
    
    // When the view appears, we adjust the frame size
    CGFloat menuWidthScale = [SampleAppMenuViewController getMenuWidthScale];
    CGRect tableFrame = CGRectMake(0, 0, menuWidthScale * self.view.frame.size.width, self.view.frame.size.height);
    [self.tableView setFrame:tableFrame];
    
    // Add a smooth shadow effect
    UIView *shadow = [[UIView alloc] initWithFrame:tableFrame];
    shadow.opaque = NO;
    shadow.layer.shadowOpacity = ShadowOpacity;
    shadow.layer.cornerRadius = ShadowRadiusCorner;
    shadow.layer.shadowRadius = ShadowRadiusCorner;
    shadow.layer.shadowOffset = CGSizeZero;
    [shadow setUserInteractionEnabled:NO];
    // use of a bezier path for the shadow around the view
    CGRect shadowRect = CGRectMake(tableFrame.size.width - 1.5*ShadowRadiusCorner, tableFrame.origin.y, 2*ShadowRadiusCorner, tableFrame.size.height);
    shadow.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowRect].CGPath;
    [self.tableView addSubview:shadow];
    
    // prepare a single tap gesture recognizer for the window containing this view
    // that will collect events outside of the current view (to track single tap on the AR view)
    windowTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnWindow:)];
    [windowTapGestureRecognizer setNumberOfTapsRequired:1];
    windowTapGestureRecognizer.cancelsTouchesInView = NO;
    windowTapGestureRecognizerAdded = NO;
    windowTapGestureRecognizer.delegate = self;

}

- (void)viewDidUnload {
    [super viewDidUnload];

    self.tableView = nil;
    self.menuDelegate = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // When the view appears, we adjust the frame size
    CGFloat menuWidthScale = [SampleAppMenuViewController getMenuWidthScale];
    CGRect tableFrame = CGRectMake(0, 0, menuWidthScale * self.view.frame.size.width, self.view.frame.size.height);
    [self.tableView setFrame:tableFrame];
    
    // this gesture recognizer must be added in viewDidAppear - won't work on viewDidLoad
    if (! windowTapGestureRecognizerAdded) {
        [self.view.window addGestureRecognizer:windowTapGestureRecognizer];
        windowTapGestureRecognizerAdded = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // as the recognizer belongs o the window, we must remove it when the view disappear
    if (windowTapGestureRecognizerAdded) {
        [self.view.window removeGestureRecognizer:windowTapGestureRecognizer];
        windowTapGestureRecognizerAdded = NO;
    }
    [super viewWillDisappear:animated];
}


- (void)handleTapOnWindow:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // we consider the coordinates in the window
        CGPoint location = [sender locationInView:nil];
        
        // test if we are outside the current view
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil])
        {
            // we dismiss the menu if the user taps outside of the view which is on the AR view.
            [self dismissMenu];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//------------------------------------------------------------------------------
#pragma mark - Autorotation
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // make the top section header bold
    if (section == 0) {
        int w = self.tableView.frame.size.width;
        int h = self.tableView.superview.frame.size.height / 12;
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(0, 0, w, h);
        label.font = [UIFont boldSystemFontOfSize:17];
        label.text = self.sampleAppFeatureName;
        label.textAlignment = NSTextAlignmentCenter;
        
        UIView *headerView = [[UIView alloc] init];
        [headerView addSubview:label];
        return headerView;
    }
    else {
        return [super tableView:tableView viewForHeaderInSection:section];
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger selSection = indexPath.section;
    NSInteger selRow = indexPath.row;
    NSInteger rowsInSection = [tableView numberOfRowsInSection:selSection];
    UITableViewCell *selCell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *selLabel = [self findLabelInCell:selCell];
    NSString *itemName = (selLabel != nil) ? selLabel.text : nil;
    
    if ([itemName isEqualToString:self.dismissItemName]) {
        if (self.menuDelegate != nil) {
            [self.menuDelegate menuDidExit];
            self.menuDelegate = nil;
        }
        
        // Jump back to the root view controller
        UINavigationController *navController = nil;
        UIViewController *rootVC = [[UIApplication sharedApplication] keyWindow].rootViewController;
        if ([rootVC isKindOfClass:[UINavigationController class]]) {
            navController = (UINavigationController*)rootVC;
        }
        else {
            navController = rootVC.navigationController;
        }
        
        [self.presentingViewController dismissViewControllerAnimated:NO completion:^(void){
            [navController popToRootViewControllerAnimated:NO];
        }];
        
        return;
    } else {
        UISwitch* sw = [self findSwitchInCell:selCell];
        if (sw != nil) {
            // CASE 1:
            // the selected cell contains a UISwitch
            // we toggle the switch
            sw.on = !sw.on;
            [self switchToggled:sw];
            return;
        }
        else if ([self isRadioButtonCell:tableView atIndexPath:indexPath]) {
            // CASE 2:
            // the selected cell is a "radio button" cell in a "radio group"
            // we enable checkmark in the selected cell
            selCell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            // and we disable checkmark on sibling cells in the same "radio group" section
            for (int r = 0; r < rowsInSection; r++) {
                if (r != selRow) {
                    UITableViewCell *siblingCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:selSection]];
                    if (siblingCell.accessoryType == UITableViewCellAccessoryCheckmark) {
                        siblingCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                }
            }
            // we notify the menu delegate about the selected item
            [self.menuDelegate menuProcess:itemName value:YES];
        }
        else {
            // CASE 3:
            // the selected cell is neither a "Switch" nor a "radio button"
            // (it's just a labeled item)
            // we notify the menu delegate about the selected item
            [self.menuDelegate menuProcess:itemName value:NO];
        }
    }
    
    // we deselect the row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self dismissMenu];
}

- (IBAction)switchToggled:(id)sender
{
    UISwitch *sw = (UISwitch*)sender;
    UITableViewCell *cell = [self findParentCell:sw];
    
    UILabel *cellLabel = [self findLabelInCell:cell];
    if (cellLabel != nil) {
        NSString *itemName = cellLabel.text;
        // we notify the menu delegate about the selected item
        [self.menuDelegate menuProcess:itemName value:sw.on];
    }

    // we deselect the row
    [cell setSelected:NO animated:YES];
    
    [self dismissMenu];
}

- (UITableViewCell*)findParentCell:(UIView*)cellSubview
{
    UIView *view = cellSubview;
    while (![view isKindOfClass:[UITableViewCell class]]) {
        view = view.superview;
    }
    return (UITableViewCell*) view;
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

- (UISwitch*)findSwitchInCell:(UITableViewCell*)cell
{
    for (UIView *view in [cell.contentView subviews]) {
        if ([view isKindOfClass:[UISwitch class]]) {
            return ((UISwitch*)view);
        }
    }
    return nil;
}

- (UITableViewCell*)findCellWithName:(NSString*)name
{
    NSInteger sections = self.tableView.numberOfSections;
    for (int section = 0; section < sections; section++) {
        NSInteger rowsInSection = [self.tableView numberOfRowsInSection:section];
        for (int row = 0; row < rowsInSection; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UILabel* label = [self findLabelInCell:cell];
            if (label != nil && [label.text isEqualToString:name]) {
                return cell;
            }
        }
    }
    return nil;
}

- (BOOL)isRadioButtonCell:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger rowsInSection = [tableView numberOfRowsInSection:section];
    for (int row = 0; row < rowsInSection; row++) {
        UITableViewCell *cellInSection = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        if (cellInSection.accessoryType == UITableViewCellAccessoryCheckmark) {
            // we found at least one "Checkmark" item within the same section
            // so yes, we are in a "radio group"
            return YES;
        }
    }
    return NO;
}

- (void)setValue:(BOOL)value forMenuItem:(NSString*)name
{
    UITableViewCell* cell = [self findCellWithName:name];
    if (cell == nil)
        return;
    
    UISwitch* sw = [self findSwitchInCell:cell];
    if (sw != nil) {
        sw.on = value;
        return;
    }
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    if ([self isRadioButtonCell:self.tableView atIndexPath:indexPath]) {
        cell.accessoryType = value ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        if (value) {
            // if the cell is "checked" (value == YES)
            // we must disable the checkmarks on all sibling cells in the same "radio group" section
            NSInteger rowsInSection = [self.tableView numberOfRowsInSection:indexPath.section];
            for (int r = 0; r < rowsInSection; r++) {
                if (r != indexPath.row) {
                    UITableViewCell *siblingCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:indexPath.section]];
                    if (siblingCell.accessoryType == UITableViewCellAccessoryCheckmark) {
                        siblingCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                }
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (void)swipeGestureAction:(UISwipeGestureRecognizer*)gesture
{
    [self dismissMenu];
}

#pragma mark - Navigation

- (void)dismissMenu
{
    showingMenu = NO;
    // we dismiss the menu with a custom animated transition
    [self performSegueWithIdentifier:self.backSegueId sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isKindOfClass:[UnwindMenuSegue class]]) {
        if (self.menuDelegate != nil) {
            [self.menuDelegate menuDidExit];
            self.menuDelegate = nil;
        }
    }
}

@end

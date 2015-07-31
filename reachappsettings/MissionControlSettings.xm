#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import <libactivator/libactivator.h>

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.reachapp.settings.plist"

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

@interface PSViewController (SettingsKit2)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

@interface ReachAppMCSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppMCSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:255/255.0f green:205/255.0f blue:2/255.0f alpha:1.0f].CGColor,
        (id) [UIColor colorWithRed:255/255.0f green:227/255.0f blue:113/255.0f alpha:1.0f].CGColor, 
    ];
    header.shouldBlend = NO;
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MissionControlHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(32, 32)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}
-(UIColor*) tintColor { return [UIColor colorWithRed:255/255.0f green:205/255.0f blue:2/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }
-(NSString*) customTitle { return @"MissionControl"; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"missionControlEnabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"replaceAppSwitcherWithMC",
                 @"label": @"Replace App Switcher",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
                 @{ },
             @{
                    @"cell": @"PSLinkCell",
                    @"action": @"showActivatorAction",
                    @"label": @"Secondary Activation Method",
                    //@"enabled": objc_getClass("LAEventSettingsController") != nil,
                 },
             ];
}
-(void) showActivatorAction
{
    id activator = objc_getClass("LAListenerSettingsViewController");
    if (!activator)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"Multiplexer") message:@"Activator must be installed to use this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        LAListenerSettingsViewController *vc = [[objc_getClass("LAListenerSettingsViewController") alloc] init];
        vc.listenerName = @"com.efrederickson.reachapp.missioncontrol.activatorlistener";
        [self.rootController pushViewController:vc animated:YES];
    }
}
@end
#import "RABackgrounder.h"
#import "RASettings.h"

NSMutableDictionary *temporaryOverrides = [NSMutableDictionary dictionary];

@implementation RABackgrounder
+(id) sharedInstance
{
	SHARED_INSTANCE(RABackgrounder);
}

-(BOOL) shouldAutoLaunchApplication:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"autoLaunch"] == nil ? NO : [dict[@"autoLaunch"] boolValue]);
}

-(BOOL) shouldAutoRelaunchApplication:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"autoRelaunch"] == nil ? NO : [dict[@"autoRelaunch"] boolValue]);
}

-(NSInteger) popTemporaryOverrideForApplication:(NSString*)identifier
{
	if (![temporaryOverrides objectForKey:identifier])
		return -1;
	RABackgroundMode override = (RABackgroundMode)[temporaryOverrides[identifier] intValue];
	[temporaryOverrides removeObjectForKey:identifier];
	return override;
}

-(NSInteger) popTemporaryOverrideForApplication:(NSString*)identifier is:(RABackgroundMode)mode
{
	NSInteger popped = [self popTemporaryOverrideForApplication:identifier];
	return popped == -1 ? -1 : (popped == mode ? 1 : 0);
}

-(BOOL) shouldKeepInForeground:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;

	NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier is:RABackgroundModeForcedForeground];
	return enabled && (temporaryOverride == -1 ? ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeForcedForeground) : temporaryOverride);
}

-(BOOL) shouldSuspendImmediately:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;

	NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier is:RABackgroundModeSuspendImmediately];
	return enabled && (temporaryOverride == -1 ? ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeSuspendImmediately) : temporaryOverride);
}

-(BOOL) preventKillingOfIdentifier:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"preventDeath"] == nil ? NO : [dict[@"preventDeath"] boolValue]);
}

-(NSInteger) backgroundModeForIdentifier:(NSString*)identifier
{
	NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier];
	if (temporaryOverride != -1)
		return temporaryOverride;

	return [[RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier][@"backgroundMode"] intValue];
}

-(BOOL) hasUnlimitedBackgroundTime:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"unlimitedBackgrounding"] == nil ? NO : [dict[@"unlimitedBackgrounding"] boolValue]);
}

-(BOOL) killProcessOnExit:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeForceNone);
}

-(void) temporarilyApplyBackgroundingMode:(RABackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close
{
	temporaryOverrides[app.bundleIdentifier] = @(mode);

	if (close)
	{
        FBWorkspaceEvent *event = [objc_getClass("FBWorkspaceEvent") eventWithName:@"ActivateSpringBoard" handler:^{
            SBDeactivationSettings *settings = [[objc_getClass("SBDeactivationSettings") alloc] init];
            [settings setFlag:YES forDeactivationSetting:20];
            [settings setFlag:NO forDeactivationSetting:2];
            [UIApplication.sharedApplication._accessibilityFrontMostApplication _setDeactivationSettings:settings];
     
            SBAppToAppWorkspaceTransaction *transaction = [[objc_getClass("SBAppToAppWorkspaceTransaction") alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
            [transaction begin];
        }];
        [(FBWorkspaceEventQueue*)[objc_getClass("FBWorkspaceEventQueue") sharedInstance] executeOrAppendEvent:event];
	}
}

-(BOOL) application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode
{
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return enabled && [val boolValue];
}

-(RAIconIndicatorViewInfo) allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier
{
	int info = RAIconIndicatorViewInfoNone;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeNative)
		info |= RAIconIndicatorViewInfoNative;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground)
		info |= RAIconIndicatorViewInfoForced;

	if ([self killProcessOnExit:identifier])
		info |= RAIconIndicatorViewInfoForceDeath;

	if ([self preventKillingOfIdentifier:identifier])
		info |= RAIconIndicatorViewInfoUnkillable;

	if ([self hasUnlimitedBackgroundTime:identifier])
		info |= RAIconIndicatorViewInfoUnlimitedBackgroundTime;

	if ([self shouldSuspendImmediately:identifier])
		info |= RAIconIndicatorViewInfoSuspendImmediately;

	return (RAIconIndicatorViewInfo)info;
}

-(void) updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(RAIconIndicatorViewInfo)info
{
	SBIconView *ret = nil;
    if ([[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)])
    {
        // iOS 8.0+

        SBIcon *icon = [[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] applicationIconForBundleIdentifier:identifier];
        ret = [[objc_getClass("SBIconViewMap") homescreenMap] mappedIconViewForIcon:icon];
    }
    else
    {
        // iOS 7.X
        SBIcon *icon = [[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] applicationIconForDisplayIdentifier:identifier];
        ret = [[objc_getClass("SBIconViewMap") homescreenMap] mappedIconViewForIcon:icon];
    }

    [ret RA_updateIndicatorView:info];
}

-(BOOL) shouldShowIndicatorForIdentifier:(NSString*)identifier
{
	NSDictionary *dct = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [RASettings.sharedInstance shouldShowIconIndicatorsGlobally];
	return globalSetting ?: ([dct objectForKey:@"showIndicatorOnIcon"] == nil ? YES : [dct[@"showIndicatorOnIcon"] boolValue]);
}
@end
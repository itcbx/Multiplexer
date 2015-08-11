#import "RAKeyboardStateListener.h"
#import "headers.h"
#import <execinfo.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RAMessaging.h"
#import "RAMessagingClient.h"
#import "RAKeyboardWindow.h"
#import "RARemoteKeyboardView.h"
#import "RADesktopManager.h"

extern BOOL overrideDisableForStatusBar;
BOOL isShowing = NO;

@implementation RAKeyboardStateListener
+ (instancetype)sharedInstance
{
    SHARED_INSTANCE(RAKeyboardStateListener);
}

- (void)didShow:(NSNotification*)notif
{
    NSLog(@"[ReachApp] keyboard didShow");
    _visible = YES;
    _size = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, NULL, true);
    [RAMessagingClient.sharedInstance notifyServerOfKeyboardSizeUpdate:_size];

    if ([RAMessagingClient.sharedInstance shouldUseExternalKeyboard])
    {
        [RAMessagingClient.sharedInstance notifyServerToShowKeyboard];
        isShowing = YES;
    }
}

- (void)didHide
{
    NSLog(@"[ReachApp] keyboard didHide");
    _visible = NO;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, NULL, true);

    if ([RAMessagingClient.sharedInstance shouldUseExternalKeyboard] || isShowing)
    {
        isShowing = NO;
        [RAMessagingClient.sharedInstance notifyServerToHideKeyboard];
    }
}

- (id)init
{
    if ((self = [super init])) 
    {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShow:) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

-(void) _setVisible:(BOOL)val { _visible = val; }
-(void) _setSize:(CGSize)size { _size = size; }
@end

void externalKeyboardDidShow(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    [RAKeyboardStateListener.sharedInstance _setVisible:YES];
}

void externalKeyboardDidHide(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    //NSLog(@"[ReachApp] externalKeyboardDidHide");
    [RAKeyboardStateListener.sharedInstance _setVisible:NO];
}

%hook UIKeyboard
-(void) activate
{
    %orig;

    unsigned int contextID = UITextEffectsWindow.sharedTextEffectsWindow._contextId;
    [RAMessagingClient.sharedInstance notifyServerWithKeyboardContextId:contextID];
}
%end

%ctor
{
    // Any process
    [RAKeyboardStateListener sharedInstance];

    // Just SpringBoard
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, externalKeyboardDidShow, CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, externalKeyboardDidHide, CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
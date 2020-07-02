#import <Foundation/Foundation.h>
#import "Utils.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString * nsDomainString = @"com.tareq.orientationcontrol";
static NSString * nsNotificationString = @"com.tareq.orientationcontrol/preferences.changed";
static BOOL enabled;

static BOOL nonUserSwitch = false;

%hook SpringBoard

-(void)frontDisplayDidChange:(id)newDisplay {

    %orig(newDisplay);

    if (newDisplay == nil) {
			// In Home Screen

			if (nonUserSwitch == true) {

				nonUserSwitch = false;

				UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Disable Rotation Lock"
																		 message: nil
																		 preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Unlock" style:UIAlertActionStyleDefault
					 handler:^(UIAlertAction * action) {
					 [[%c(SBOrientationLockManager) sharedInstance] unlock];
				 }];
				UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Keep Locked" style:UIAlertActionStyleCancel
					handler:^(UIAlertAction * action) { }];

				[alert addAction:defaultAction];
				[alert addAction:cancelAction];

				[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];

			}

    } else if ([newDisplay isKindOfClass:%c(SBApplication)]) {
			// In An Application



    }

}

%end

%hook SBSceneView

-(void)_setOrientation:(long long)orientation {
		/*
			orientation as an LLI:
					* 1 is portrait
					* 3 is landscape, home button on right
					* 4 is landscape, home button on left
		*/

		if (self.orientation != orientation && self.orientation == 1 && !nonUserSwitch) {

			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"SBSceneView"
																	 message: [NSString stringWithFormat:@"%lli > %lli", self.orientation, orientation]
																	 preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Switch" style:UIAlertActionStyleDefault
				 handler:^(UIAlertAction * action) { }];
			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Nope" style:UIAlertActionStyleCancel
				handler:^(UIAlertAction * action) {
					nonUserSwitch = true;
					[[%c(SBOrientationLockManager) sharedInstance] lock];
			}];

			[alert addAction:defaultAction];
			[alert addAction:cancelAction];

			[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];

		}

    %orig;

}
%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSNumber * enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
	enabled = (enabledValue)? [enabledValue boolValue] : YES;
}

%ctor {
	// Set variables on start up
	notificationCallback(NULL, NULL, NULL, NULL, NULL);

	// Register for 'PostNotification' notifications
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);

	// Add any personal initializations

}

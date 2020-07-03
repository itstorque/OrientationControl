#import <Foundation/Foundation.h>
#import "Utils.h"
#import "toggle.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString * nsDomainString = @"com.tareq.orientationcontrol";
static NSString * nsNotificationString = @"com.tareq.orientationcontrolpreferences/preferences.changed";
static NSString * prefsFile = @"/private/var/mobile/Library/Preferences/com.tareq.orientationcontrol.plist";

// Preferences
static BOOL  enabled;
static BOOL  appDisabled;
static BOOL  useAlertsInstead = false;
static float timeIntervalForHide = 5.0;

// Internal Variables
static BOOL nonUserSwitch = false;
OrientationControlToggle* toggle;

#define lockRotation \
						nonUserSwitch = true;\
						[[%c(SBOrientationLockManager) sharedInstance] lock];

%hook SpringBoard

-(void)frontDisplayDidChange:(id)newDisplay {

	%orig(newDisplay);

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc]
		initWithContentsOfFile: prefsFile];

	enabled = ([prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES);

	if (newDisplay == nil && enabled) {
		// In Home Screen

		if (nonUserSwitch == true && [[%c(SBOrientationLockManager) sharedInstance] isUserLocked]) {

			nonUserSwitch = false;

			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Disable Rotation Lock"
				message: nil
				preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Unlock"
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) {

					[[%c(SBOrientationLockManager) sharedInstance] unlock];

			}];

			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Keep Locked"
				style:UIAlertActionStyleCancel
				handler:^(UIAlertAction * action) { }];

			[alert addAction:defaultAction];
			[alert addAction:cancelAction];

			[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];

		}

	} else if ([newDisplay isKindOfClass:%c(SBApplication)] && enabled) {
		// In An Application

		NSString* identifier = ((SBApplication *) newDisplay).bundleIdentifier;

		if ([self isAppDisabled: identifier fromPrefs: prefs]) {

			appDisabled = YES;

		}

	}

}

-(void)applicationDidFinishLaunching:(id)application {

	//TODO: link variable that checks if use alert view or floating toggle check if we need to update enabled
	//TODO: Add timer modification option in setting

	if (enabled) {

		toggle = [[%c(OrientationControlToggle) alloc] init:!useAlertsInstead withCallback:^(){

			lockRotation;
			[toggle hide];

		}];

	}

	%orig(application);

}

%new

-(NSSet*)getAllDisabledApps:(NSMutableDictionary*)prefs {

    NSMutableSet *result = [@[] mutableCopy];

    for (NSString *keyval in [prefs allKeys]) {

        if ([keyval rangeOfString:@"disabledIn-"].length > 0) {

            NSString *identifier = [keyval substringFromIndex: [keyval rangeOfString:@"disabledIn-"].length];

            if ([[prefs valueForKey: keyval] boolValue] == YES) {

                [result addObject:identifier];

            }

        }

    }

	return result;

}

%new

-(BOOL)isAppDisabled:(NSString*)identifier fromPrefs:(NSMutableDictionary*)prefs {

	return (prefs[[NSString stringWithFormat:@"%@%@", @"disabledIn-", identifier]] ? YES : NO);

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

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc]
		initWithContentsOfFile: prefsFile];

	enabled = ([prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES);

	if (self.orientation != orientation && self.orientation == 1 && !nonUserSwitch && enabled && !appDisabled) {

		if (useAlertsInstead) {

			[self showAlert];

		} else {

			[toggle show];

			[NSTimer scheduledTimerWithTimeInterval: timeIntervalForHide
			    target:[NSBlockOperation blockOperationWithBlock: ^{

					[toggle hide];

				}]
			    selector: @selector(main)
			    userInfo:nil
			    repeats:NO];

		}

	}

	%orig;

}

%new

-(void)showAlert {

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"OrientationControl"
		message: @"Do you want to rotate the screen?"
		preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Rotate"
		style:UIAlertActionStyleDefault
		handler:^(UIAlertAction * action) { }];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Remain Portrait"
		style:UIAlertActionStyleCancel
		handler:^(UIAlertAction* action) {

			lockRotation;

	}];

	[alert addAction:defaultAction];
	[alert addAction:cancelAction];

	[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];

}

%end

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {

	CFPreferencesAppSynchronize(CFSTR("com.tareq.orientationcontrol"));

}

%ctor {

	// Register for 'PostNotification' notifications

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR("com.tareq.orientationcontrol.preferencechanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc]
		initWithContentsOfFile: prefsFile];

	enabled = ([prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES);
	appDisabled = false;

}

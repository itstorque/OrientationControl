#import <Foundation/Foundation.h>
#import "Utils.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString * nsDomainString = @"com.tareq.orientationcontrol";
static NSString * nsNotificationString = @"com.tareq.orientationcontrolpreferences/preferences.changed";
static NSString * prefsFile = @"/private/var/mobile/Library/Preferences/com.tareq.orientationcontrol.plist";
static BOOL enabled;
static BOOL appDisabled;

static BOOL nonUserSwitch = false;

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

		// NSString* title = @"SBApplication Not Disabled";
		NSString* identifier = ((SBApplication *) newDisplay).bundleIdentifier;

		if ([self isAppDisabled: identifier fromPrefs: prefs]) {

			// title = @"SBApplication Is Disabled";

			appDisabled = YES;

		}

		// UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
		// 	message: [NSString stringWithFormat: @"%@\n%@\n%@",
		// 		identifier,
		// 		[NSString stringWithFormat:@"%@%@", @"disabledIn-", identifier],
		// 		prefs[[NSString stringWithFormat:@"%@%@", @"disabledIn-", identifier]]
		// 	]
		// 	preferredStyle:UIAlertControllerStyleAlert];
		//
		// UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
		// 	style:UIAlertActionStyleDefault
		// 	handler:^(UIAlertAction * action) { }];
		//
		// [alert addAction:defaultAction];
		//
		// [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];

	}

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

		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"SBSceneView"
			message: [NSString stringWithFormat:@"%lli > %lli", self.orientation, orientation]
			preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Switch"
			style:UIAlertActionStyleDefault
			handler:^(UIAlertAction * action) { }];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Nope"
			style:UIAlertActionStyleCancel
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

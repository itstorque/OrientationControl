#import <UIKit/UIWindow+Private.h>

@interface SBSceneView : NSObject

@property (readonly, nonatomic) long long orientation;

-(void)_setOrientation:(long long)orientation;

// Added methods
-(void)showAlert;

@end

@interface SBOrientationLockManager : NSObject

+(id)sharedInstance;
-(BOOL)isUserLocked;

@end

@interface SpringBoard : NSObject

-(NSArray*)getAllDisabledApps:(NSMutableDictionary*)prefs;
-(BOOL)isAppDisabled:(NSString*)identifier fromPrefs:(NSMutableDictionary*)prefs;

@end

@interface SBApplication : NSObject

-(NSString*)bundleIdentifier;

@end

@interface CAPackage : NSObject

+(id)packageWithContentsOfURL:(id)arg1 type:(id)arg2 options:(id)arg3 error:(id)arg4;

@end

@interface CCUICAPackageView : UIView

@property (nonatomic, retain) CAPackage *package;
-(void)setStateName:(id)arg1;

@end

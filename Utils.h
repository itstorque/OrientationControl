@interface SBSceneView : NSObject

@property (readonly, nonatomic) long long orientation;

-(void)_setOrientation:(long long)orientation;

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

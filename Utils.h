@interface SBSceneView : NSObject

@property (readonly, nonatomic) long long orientation;

-(void)_setOrientation:(long long)orientation;

@end

@interface SBOrientationLockManager : NSObject
+(id)sharedInstance;
@end

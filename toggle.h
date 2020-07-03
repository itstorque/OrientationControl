#import <Foundation/Foundation.h>
#import "Utils.h"

@interface OrientationControlToggle : NSObject

@property (nonatomic, strong) UIWindow* window;
@property (nonatomic, strong) UIView* view;

-(id)init:(BOOL)enabled withCallback:(void(^)(void))callback;
-(void)hide;
-(void)show;

-(void)callbackExecuter;

@end

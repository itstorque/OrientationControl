#import <Foundation/Foundation.h>
#import "toggle.h"

static CGFloat displayHeight;
static CGFloat displayWidth;

NSString* const orientationLockGlyphPath = @"/System/Library/ControlCenter/Bundles/OrientationLockModule.bundle/OrientationLock.ca";

void (^_callback)(void);

extern NSString* const kCAPackageTypeCAMLBundle;

@implementation OrientationControlToggle

-(id)init:(BOOL)enabled withCallback:(void(^)(void))callback {

	self = [super init];

	_callback = [callback copy];

	if (self) {

		CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        screenSize = CGSizeMake(
			MIN(screenSize.width, screenSize.height),
		 	MAX(screenSize.width, screenSize.height)
		);

        displayWidth = screenSize.width;
        displayHeight = screenSize.height;

		self.window = [[UIWindow alloc] initWithFrame:CGRectMake(displayWidth-70, displayHeight-70, 50, 50)];
		self.window.backgroundColor = [UIColor clearColor];
		self.window.windowLevel = UIWindowLevelAlert;

		[self.window _setSecure: YES];

		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        self.view.layer.cornerRadius = 10.0;
        self.view.layer.masksToBounds = YES;

        [self.view setBackgroundColor: [UIColor clearColor]];

        [self.view setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.view setUserInteractionEnabled:YES];

		UIVisualEffectView* blurEffectView;
		blurEffectView.alpha = 1.0;
        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle: UIBlurEffectStyleDark];
        blurEffectView = [[UIVisualEffectView alloc] initWithEffect: blurEffect];
        blurEffectView.frame = self.view.bounds;
        [self.view addSubview:blurEffectView];

		CCUICAPackageView* glyphView;
		glyphView = [[%c(CCUICAPackageView) alloc] initWithFrame: self.view.bounds];

		glyphView.package = [CAPackage packageWithContentsOfURL:[NSURL
			fileURLWithPath: orientationLockGlyphPath]
			type:kCAPackageTypeCAMLBundle
			options:nil error:nil];

		[self.view addSubview:glyphView];
		[glyphView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
		[glyphView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;

		[self.window addSubview: self.view];

		UITapGestureRecognizer* tapToToggleLock = [[UITapGestureRecognizer alloc]
			initWithTarget:self action:@selector(callbackExecuter)];
        [self.view addGestureRecognizer:tapToToggleLock];

		[self hide];

	}

	return self;

}

-(void)callbackExecuter {
	_callback();
}

-(void)hide {

	self.window.hidden = YES;
	self.window.alpha  = 0;
	[self.window setUserInteractionEnabled: NO];

}

-(void)show {

	self.window.hidden = NO;
	self.window.alpha  = 1;
	[self.window setUserInteractionEnabled: YES];

}

@end

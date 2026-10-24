#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MBProgressHUDMode) {
    MBProgressHUDModeIndeterminate,
    MBProgressHUDModeDeterminate,
    MBProgressHUDModeText,
};

@interface MBProgressHUD : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) MBProgressHUDMode mode;
@property (nonatomic, assign) float progress;

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;
@end
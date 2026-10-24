#import "MBProgressHUD.h"

@interface MBProgressHUD ()
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UIProgressView *bar;
@property (nonatomic, strong) UIToolbar *backdrop;
@end

@implementation MBProgressHUD

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;

        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:13];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
        [self addSubview:_label];

        _indicator = [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_indicator];

        _bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:_bar];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    self.label.frame = CGRectMake(0, 0, w, h * 0.5);
    self.indicator.frame = CGRectMake(w/2 - 20, 6, 40, 40);
    self.bar.frame = CGRectMake(10, h * 0.72, w - 20, 4);
    self.bar.hidden = (self.mode != MBProgressHUDModeDeterminate);
    self.indicator.hidden = (self.mode == MBProgressHUDModeText);
    if (self.mode == MBProgressHUDModeText) {
        self.label.frame = self.bounds;
    }
}

- (void)setProgress:(float)progress {
    _progress = progress;
    self.bar.progress = progress;
}

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    CGSize s = view.bounds.size;
    MBProgressHUD *hud = [[self alloc]
        initWithFrame:CGRectMake(s.width/2 - 80, s.height/2 - 70, 160, 120)];
    [view addSubview:hud];
    [hud.indicator startAnimating];
    if (animated) {
        hud.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{ hud.alpha = 1; }];
    }
    return hud;
}

- (void)hideAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2
            animations:^{ self.alpha = 0; }
            completion:^(BOOL done){ [self removeFromSuperview]; }];
    } else {
        [self removeFromSuperview];
    }
}

- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            [self hideAnimated:animated];
        });
}

@end
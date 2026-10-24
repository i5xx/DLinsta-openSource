// DLInsta — Instagram photo/video downloader tweak (reconstructed).
//
// Hook targets:
//   CONFIRMED (seen in the original binary): IGDirectThreadViewController, IGMenuItem,
//     and selector names like controlsOverlayControllerDidTapLikeButton,
//     videoPlayerOverlayControllerDidDoubleTap:locationInfo:, UFIButtonBarDidTapOnLike:.
//   INFERRED (community-standard Instagram class names, adjust per IG version):
//     IGFeedItemPhotoCell, IGFeedVideoCell, IGMedia.
//
// Original used obfuscated names to evade detection; we use clear names here.

#import <UIKit/UIKit.h>
#import "DLManager.h"
#import "DLGetSafe.h"

// Detect a long-press on feed photo/video cells → show download options.
%group FeedDownloads

%hook IGFeedItemPhotoCell
- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        if ([g isKindOfClass:[UILongPressGestureRecognizer class]] && g.view == self) return;
    }
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(dl_didLongPress:)];
    [self addGestureRecognizer:lp];
}

%new
- (void)dl_didLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    if (![DLManager passesAuthentication]) return;
    id media = [DLGetSafe value:@"item" from:self] ?: self;
    NSURL *url = [[DLManager shared] mediaURLFromObject:media];
    UIViewController *vc = [self dl_controller];
    [[DLManager shared] showOptionsForURL:url mediaObject:media from:vc];
}

%new
- (UIViewController *)dl_controller {
    UIResponder *r = self;
    while (r) {
        if ([r isKindOfClass:[UIViewController class]]) return (UIViewController *)r;
        r = [r nextResponder];
    }
    return nil;
}
%end

%hook IGFeedVideoCell
- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        if ([g isKindOfClass:[UILongPressGestureRecognizer class]]) return;
    }
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(dl_videoLongPress:)];
    [self addGestureRecognizer:lp];
}

%new
- (void)dl_videoLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    id media = [DLGetSafe value:@"item" from:self] ?: self;
    NSURL *url = [[DLManager shared] videoURLFromObject:media]
                 ?: [[DLManager shared] mediaURLFromObject:media];
    UIResponder *r = self;
    while (r && ![r isKindOfClass:[UIViewController class]]) r = [r nextResponder];
    [[DLManager shared] showOptionsForURL:url mediaObject:media from:(UIViewController *)r];
}
%end

%end // FeedDownloads

// Direct-message download support (CONFIRMED class IGDirectThreadViewController).
%group DMDownload

%hook IGDirectThreadViewController
%new
- (void)dl_installDMHook {
    // Called once; attach a nav-bar "Download" button to the thread.
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:@"DL"
        style:UIBarButtonItemStylePlain target:self action:@selector(dl_downloadLatest:)];
    self.navigationItem.rightBarButtonItems =
        [self.navigationItem.rightBarButtonItems ?: @[] arrayByAddingObject:b];
}

- (void)viewDidLoad {
    %orig;
    [self dl_installDMHook];
}

%new
- (void)dl_downloadLatest:(id)sender {
    // INFERRED: latest message media is stored on the data source; safe-get it.
    id ds = [DLGetSafe value:@"dataSource" from:self];
    id latest = nil;
    if ([ds respondsToSelector:@selector(currentVisibleMessage)])
        latest = [ds valueForKey:@"currentVisibleMessage"];
    if (!latest) latest = [DLGetSafe value:@"currentMessage" from:ds];
    NSURL *url = [[DLManager shared] mediaURLFromObject:latest];
    [[DLManager shared] downloadAndSaveURL:url showIn:self.view];
}
%end

%end // DMDownload

%ctor {
    %init(FeedDownloads);
    %init(DMDownload);
}
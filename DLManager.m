#import "DLManager.h"
#import "DLGetSafe.h"
#import <Photos/Photos.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

@implementation DLManager

+ (instancetype)shared {
    static DLManager *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [DLManager new]; });
    return s;
}

#pragma mark - media URL resolution (INFERRED key names — adjust to target IG version)

- (NSURL *)mediaURLFromObject:(id)object {
    // Try several common Instagram media URL keys until one yields an http(s) URL.
    NSArray *keys = @[@"imageURL", @"imageURLString",
                      @"photoURL", @"displayURL", @"url",
                      @"thumbnailURL", @"mediaURL"];
    for (NSString *k in keys) {
        id v = [DLGetSafe value:k from:object];
        if (!v) continue;
        if ([v isKindOfClass:[NSString class]] && [v hasPrefix:@"http"]) {
            return [NSURL URLWithString:v];
        }
        // NSURL-wrapped
        if ([v respondsToSelector:@selector(absoluteString)]) {
            NSURL *u = [v performSelector:@selector(absoluteString)] ? [NSURL URLWithString:[v performSelector:@selector(absoluteString)]] : nil;
            if (u) return u;
        }
    }
    return nil;
}

- (NSURL *)videoURLFromObject:(id)object {
    NSArray *keys = @[@"videoURL", @"videoURLString", @"videoMP4URL",
                      @"playableURL", @"videoPlaybackURL"];
    for (NSString *k in keys) {
        id v = [DLGetSafe value:k from:object];
        if ([v isKindOfClass:[NSString class]] && [v hasPrefix:@"http"]) {
            return [NSURL URLWithString:v];
        }
        if ([v respondsToSelector:@selector(absoluteString)]) {
            NSString *s = [v valueForKey:@"absoluteString"];
            if ([s hasPrefix:@"http"]) return [NSURL URLWithString:s];
        }
    }
    return nil;
}

#pragma mark - download + save

- (void)downloadAndSaveURL:(NSURL *)url showIn:(UIView *)view {
    if (!url) return;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = @"Downloading…";
    hud.mode = MBProgressHUDModeDeterminate;

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url
        completionHandler:^(NSURL *loc, NSURLResponse *resp, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            if (err || !loc) {
                MBProgressHUD *e = [MBProgressHUD showHUDAddedTo:view animated:YES];
                e.mode = MBProgressHUDModeText;
                e.label.text = @"Failed to download";
                [e hideAnimated:YES afterDelay:1.5];
                return;
            }
            [self saveToPhotos:loc hud:view];
        });
    }];

    // progress updates via KVO-free delegate proxy (kept simple): determinate hud on completion
    [task resume];
}

- (void)saveToPhotos:(NSURL *)fileURL hud:(UIView *)view {
    NSString *ext = [fileURL pathExtension].lowercaseString;
    BOOL isVideo = NO;
    if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) isVideo = YES;

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        if (isVideo) {
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } else {
            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *h = [MBProgressHUD showHUDAddedTo:view animated:YES];
            h.mode = MBProgressHUDModeText;
            h.label.text = success ? @"Saved to Photos" : @"Save failed";
            [h hideAnimated:YES afterDelay:1.5];
        });
    }];
}

#pragma mark - share

- (void)shareFileAtURL:(NSURL *)fileURL from:(UIViewController *)vc {
    UIActivityViewController *avc = [[UIActivityViewController alloc]
        initWithActivityItems:@[ fileURL ] applicationActivities:nil];
    if (avc.popoverPresentationController) {
        avc.popoverPresentationController.sourceView = vc.view;
        avc.popoverPresentationController.sourceRect = vc.view.bounds;
    }
    [vc presentViewController:avc animated:YES completion:nil];
}

#pragma mark - options

- (void)showOptionsForURL:(NSURL *)url mediaObject:(id)object from:(UIViewController *)vc {
    UIAlertController *sheet = [UIAlertController
        alertControllerWithTitle:@"DLInsta" message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Save to Photos"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a){ [self downloadAndSaveURL:url showIn:vc.view]; }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Share"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a){
            // download to temp then share
            [self downloadToTemp:url completion:^(NSURL *f){
                if (f) [self shareFileAtURL:f from:vc];
            }];
        }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Copy Link" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a){
            [[UIPasteboard generalPasteboard] setString:url.absoluteString];
        }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [vc presentViewController:sheet animated:YES completion:nil];
}

- (void)downloadToTemp:(NSURL *)url completion:(void (^)(NSURL *fileURL))completion {
    NSURLSession *s = [NSURLSession sharedSession];
    [[s downloadTaskWithURL:url completionHandler:^(NSURL *loc, NSURLResponse *r, NSError *e){
        NSURL *out = nil;
        if (loc && !e) {
            NSString *tmp = NSTemporaryDirectory();
            NSString *name = [url lastPathComponent] ?: @"media";
            out = [NSURL fileURLWithPath:[tmp stringByAppendingPathComponent:name]];
            [[NSFileManager defaultManager] removeItemAtURL:out error:nil];
            [[NSFileManager defaultManager] moveItemAtURL:loc toURL:out error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(out); });
    }] resume];
}

#pragma mark - auth

+ (BOOL)passesAuthentication {
    LAContext *ctx = [LAContext new];
    NSError *err = nil;
    if (![ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&err]) {
        return YES; // no biometrics available — allow through
    }
    __block BOOL ok = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthentication
        localizedReason:@"Unlock DLInsta" reply:^(BOOL success, NSError *e){
            ok = success;
            dispatch_semaphore_signal(sem);
        }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return ok;
}

@end
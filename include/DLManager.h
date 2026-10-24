#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// Download + save + share manager (mirrors the `DLTMore` / `DLTTrim` / download
/// behavior of the original binary).
@interface DLManager : NSObject
+ (instancetype)shared;

/// Resolve a media URL (image or video) from an Instagram media object or view.
- (NSURL *)mediaURLFromObject:(id)object;
- (NSURL *)videoURLFromObject:(id)object;

/// Download media at URL, showing an MBProgressHUD over `view`, then save to Photos.
- (void)downloadAndSaveURL:(NSURL *)url showIn:(UIView *)view;

/// Present a share sheet for media saved to a file URL.
- (void)shareFileAtURL:(NSURL *)fileURL from:(UIViewController *)vc;

/// Prompt an options action sheet (Download / Share / Copy link / Trim).
- (void)showOptionsForURL:(NSURL *)url mediaObject:(id)object from:(UIViewController *)vc;

/// Optional Face ID / passcode gate.
+ (BOOL)passesAuthentication;
@end
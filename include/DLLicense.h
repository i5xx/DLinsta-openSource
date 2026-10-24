#import <Foundation/Foundation.h>

/// License/activation model (reconstructs the binary's email/token/price system).
/// Mirrors: class `sbr2k1p0bf2s436` (email + token model),
///          `startAPIRequest:policy:successHandler:failureHandler:` (server call),
///          `pape4bzcwdmt0fl:title:subtitle:price:` (purchase modal),
///          `standardUserDefaults` (persistence).
@interface DLLicense : NSObject
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *token;

+ (instancetype)shared;

/// Read persisted license state (email/token/activated) from NSUserDefaults.
- (void)loadFromDefaults;
- (void)saveToDefaults;

/// Validate email+token against the license server.
- (void)activateWithEmail:(NSString *)email
                    token:(NSString *)token
               completion:(void (^)(BOOL success, NSString *message))completion;

/// Whether the tweak is licensed (cached `activated` flag).
@property (nonatomic, readonly, getter=isLicensed) BOOL licensed;

/// A title/subtitle/price string for the purchase prompt.
- (NSString *)licensePrompt;
@end
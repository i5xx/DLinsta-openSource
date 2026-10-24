#import <Foundation/Foundation.h>

/// Safe value getter (mirrors the binary's `SafeGetters` class):
/// reads a KVC value without crashing if the key/ivar does not exist.
@interface DLGetSafe : NSObject
+ (id)value:(NSString *)key from:(id)obj;
+ (NSString *)string:(NSString *)key from:(id)obj;
+ (NSArray *)array:(NSString *)key from:(id)obj;
+ (BOOL)boolValue:(NSString *)key from:(id)obj;
@end
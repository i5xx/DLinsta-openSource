#import "DLGetSafe.h"

@implementation DLGetSafe

+ (id)value:(NSString *)key from:(id)obj {
    if (!obj || !key) return nil;
    @try { return [obj valueForKey:key]; }
    @catch (NSException *e) { return nil; }
}

+ (NSString *)string:(NSString *)key from:(id)obj {
    id v = [self value:key from:obj];
    if ([v isKindOfClass:[NSString class]]) return v;
    if ([v respondsToSelector:@selector(stringValue)]) return [v stringValue];
    return nil;
}

+ (NSArray *)array:(NSString *)key from:(id)obj {
    id v = [self value:key from:obj];
    return [v isKindOfClass:[NSArray class]] ? v : nil;
}

+ (BOOL)boolValue:(NSString *)key from:(id)obj {
    id v = [self value:key from:obj];
    if ([v isKindOfClass:[NSNumber class]]) return [v boolValue];
    if ([v isKindOfClass:[NSString class]]) return [v boolValue];
    return NO;
}

@end
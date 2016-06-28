#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SoraErrorCode) {
    SoraErrorCodeJSONKeyNotFoundError,
};

extern NSString * const __nonnull SoraErrorDomain;

extern NSString * const __nonnull SoraErrorKeyJSONKey;

@interface SoraError : NSError

- (nullable instancetype)initWithCode:(SoraErrorCode)code
                             userInfo:(nullable NSDictionary *)dict;

+ (nullable instancetype)JSONKeyNotFoundError:(nonnull NSString *)JSONKey;

@end
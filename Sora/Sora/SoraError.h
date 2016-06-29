#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SoraErrorCode) {
    SoraErrorCodeStringEncodingError,
    SoraErrorCodeBinaryMessageError,
    SoraErrorCodeInvalidJSONObjectError,
    SoraErrorCodeJSONKeyNotFoundError,
    SoraErrorCodeUnknownTypeError,
    SoraErrorCodeOfferResponseError,
    SoraErrorCodeWebSocketError,
};

extern NSString * const __nonnull SoraErrorDomain;

extern NSString * const __nonnull SoraErrorKeyString;
extern NSString * const __nonnull SoraErrorKeyData;
extern NSString * const __nonnull SoraErrorKeyJSONObject;
extern NSString * const __nonnull SoraErrorKeyJSONKey;

// SoraErrorCodeOfferResponseError
extern NSString * const __nonnull SoraErrorKeyJSONError;

// SoraErrorCodeWebSocketError
extern NSString * __nonnull const SoraErrorKeyWebSocketError;

@interface SoraError : NSError

- (nullable instancetype)initWithCode:(SoraErrorCode)code
                             userInfo:(nullable NSDictionary *)dict;

+ (nullable instancetype)stringEncodingError:(nonnull NSString *)string;
+ (nullable instancetype)JSONKeyNotFoundError:(nonnull NSString *)JSONKey;

@end
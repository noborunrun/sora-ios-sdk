#import "SoraError.h"

NSString * const __nonnull SoraErrorDomain = @"SoraErrorDomain";

NSString * const __nonnull SoraErrorKeyString = @"String";
NSString * const __nonnull SoraErrorKeyData = @"Data";
NSString * const __nonnull SoraErrorKeyJSONObject = @"JSONObject";
NSString * const __nonnull SoraErrorKeyJSONKey = @"JSONKey";
NSString * const __nonnull SoraErrorKeyJSONError = @"JSONError";
NSString * __nonnull const SoraErrorKeyWebSocketError = @"WebSocketError";

@implementation SoraError

- (nullable instancetype)initWithCode:(SoraErrorCode)code
                             userInfo:(nullable NSDictionary *)dict
{
    return [super initWithDomain: SoraErrorDomain
                            code: code
                        userInfo: dict];
}

+ (nullable instancetype)stringEncodingError:(nonnull NSString *)string
{
    return [[self alloc] initWithCode: SoraErrorCodeStringEncodingError
                             userInfo: @{SoraErrorKeyString:string}];
}

+ (nullable instancetype)JSONKeyNotFoundError:(nonnull NSString *)JSONKey
{
    return [[self alloc] initWithCode: SoraErrorCodeJSONKeyNotFoundError
                             userInfo:
              [[NSDictionary alloc] initWithObjectsAndKeys: SoraErrorKeyJSONKey, JSONKey, nil]];
}

@end
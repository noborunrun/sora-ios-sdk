#import "SoraError.h"

NSString * const __nonnull SoraErrorDomain = @"SoraErrorDomain";

NSString * const __nonnull SoraErrorKeyJSONKey = @"JSONKey";

@implementation SoraError

- (nullable instancetype)initWithCode:(SoraErrorCode)code
                             userInfo:(nullable NSDictionary *)dict
{
    return [super initWithDomain: SoraErrorDomain
                            code: code
                        userInfo: dict];
}

+ (nullable instancetype)JSONKeyNotFoundError:(nonnull NSString *)JSONKey
{
    return [[self alloc] initWithCode: SoraErrorCodeJSONKeyNotFoundError
                             userInfo:
              [[NSDictionary alloc] initWithObjectsAndKeys: SoraErrorKeyJSONKey, JSONKey, nil]];
}

@end
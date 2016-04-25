#import "SoraConnection.h"

NSString * const SoraErrorDomain = @"SoraErrorDomain";

NSString * const SoraWebSocketErrorKey = @"SoraErrorCodeWebSocketError";

@interface SoraConnection ()

@property(nonatomic, readwrite, nonnull) NSURL *URL;

@end

@implementation SoraConnection

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
{
    self = [super init];
    if (self != nil) {
        self.URL = URL;
    }
    return self;
}

@end

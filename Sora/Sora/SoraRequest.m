#import "SoraRequest.h"

@implementation SoraRequest

- (nullable id)initWithRole:(SoraRole)role channelId:(nonnull NSString *)channelId
{
    self = [super init];
    if (self != nil) {
        self.role = role;
        self.channelId = channelId;
        self.accessToken = nil;
        self.codecType = SoraCodecTypeVP8;
    }
    return self;
}

@end

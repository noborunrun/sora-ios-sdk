#import "SoraStreamingMessage.h"

@implementation SoraStreamingMessage

- (nullable instancetype)initWithRole:(SoraRole)role
                             clientId:(nonnull NSString *)clientId
                            channelId:(nonnull NSString *)channelId
{
    self = [super init];
    if (self != nil) {
        self.role = role;
        self.clientId = clientId;
        self.channelId = channelId;
    }
    return self;
}

@end

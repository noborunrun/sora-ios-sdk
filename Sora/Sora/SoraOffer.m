#import "SoraOffer.h"

@interface SoraOffer ()

@property(nonatomic, readwrite, nonnull) NSString *clientId;
@property(nonatomic, readwrite, nonnull) NSString *SDPMessage;

@end

@implementation SoraOffer

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                               SDPMessage:(nonnull NSString *)SDPMessage
{
    self = [super init];
    if (self != nil) {
        self.clientId = clientId;
        self.SDPMessage = SDPMessage;
    }
    return self;
}

@end

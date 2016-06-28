#import "SoraAnswerRequest.h"

@implementation SoraAnswerRequest

- (nullable instancetype)initWithSDP:(nonnull NSString *)SDP
{
    self = [super init];
    if (self != nil) {
        self.SDP = SDP;
    }
    return self;
}

- (SoraMessageType)messageType
{
    return SoraMessageTypeAnswer;
}

- (nullable RTCSessionDescription *)sessionDescription
{
    return [[RTCSessionDescription alloc] initWithType: SoraSessionDescriptionTypeAnswer
                                                   sdp: self.SDP];
}

@end

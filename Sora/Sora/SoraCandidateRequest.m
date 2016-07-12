#import "SoraCandidateRequest.h"

@implementation SoraCandidateRequest

- (nullable instancetype)initWithCandidate:(nonnull NSString *)candidate
{
    self = [super init];
    if (self != nil) {
        self.candidate = candidate;
    }
    return self;
}

- (SoraMessageType)messageType
{
    return SoraMessageTypeCandidate;
}

#pragma mark SoraJSONEncoding

- (void)encodeIntoJSONObject:(nonnull NSMutableDictionary *)dict
{
    [super encodeIntoJSONObject: dict];
    dict[SoraMessageJSONKeyCandidate] = self.candidate;
}

@end

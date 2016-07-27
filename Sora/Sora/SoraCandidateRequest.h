#import <Sora/SoraMessage.h>

@interface SoraCandidateRequest : SoraMessage

@property(nonatomic, readwrite, nonnull) NSString *candidate;

- (nullable instancetype)initWithCandidate:(nonnull NSString *)candidate;

@end

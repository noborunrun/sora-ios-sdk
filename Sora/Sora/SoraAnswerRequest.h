#import <Sora/SoraMessage.h>

@interface SoraAnswerRequest : SoraMessage

@property(nonatomic, readwrite, nonnull) NSString *SDP;

- (nullable instancetype)initWithSDP:(nonnull NSString *)SDP;

- (nullable RTCSessionDescription *)sessionDescription;

@end

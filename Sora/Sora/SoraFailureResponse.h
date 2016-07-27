#import <Sora/SoraMessage.h>

/// abstract class
@interface SoraFailureResponse : SoraMessage

@property(nonatomic, readwrite, nonnull) NSString *clientId;
@property(nonatomic, readwrite, nonnull) NSString *channelId;
@property(nonatomic, readwrite) SoraFailureReason failureReason;

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                channelId:(nonnull NSString *)channelId
                            failureReason:(SoraFailureReason)failureReason;

@end

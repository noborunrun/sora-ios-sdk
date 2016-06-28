#import "SoraFailureResponse.h"

@interface SoraArchiveFailedResponse : SoraFailureResponse

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                channelId:(nonnull NSString *)channelId
                            failureReason:(SoraFailureReason)failureReason;

@end

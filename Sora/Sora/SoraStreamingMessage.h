#import <Sora/SoraMessage.h>

/// abstract class
@interface SoraStreamingMessage : SoraMessage

@property(nonatomic, readwrite) SoraRole role;
@property(nonatomic, readwrite, nonnull) NSString *clientId;
@property(nonatomic, readwrite, nonnull) NSString *channelId;

- (nullable instancetype)initWithRole:(SoraRole)role
                             clientId:(nonnull NSString *)clientId
                            channelId:(nonnull NSString *)channelId;

@end

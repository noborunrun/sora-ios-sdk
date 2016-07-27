#import <Sora/SoraStreamingMessage.h>

/// abstract class
@interface SoraSignalingResponse : SoraStreamingMessage

@property(nonatomic, readwrite) NSUInteger minites;
@property(nonatomic, readwrite) NSUInteger numberOfChannelConnections;
@property(nonatomic, readwrite) NSUInteger numberOfUpstreamConnections;
@property(nonatomic, readwrite) NSUInteger numberOfDownstreamConnections;

- (nullable instancetype)initWithRole:(SoraRole)role
                             clientId:(nonnull NSString *)clientId
                            channelId:(nonnull NSString *)channelId
                              minites:(NSUInteger)minites
           numberOfChannelConnections:(NSUInteger)numberOfChannelConnections
          numberOfUpstreamConnections:(NSUInteger)numberOfUpstreamConnections
        numberOfDownstreamConnections:(NSUInteger)numberOfDownstreamConnections;

@end

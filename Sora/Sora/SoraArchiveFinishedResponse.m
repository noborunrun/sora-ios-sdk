#import "SoraArchiveFinishedResponse.h"

@implementation SoraArchiveFinishedResponse

- (nullable instancetype)initWithRole:(SoraRole)role
                             clientId:(nonnull NSString *)clientId
                            channelId:(nonnull NSString *)channelId
                         creationTime:(nonnull NSDate *)creationTime
                             filePath:(nonnull NSString *)filePath
                             fileName:(nonnull NSString *)fileName
                             fileSize:(NSUInteger)fileSize
                       videoCodecType:(SoraVideoCodecType)videoCodecType
                       audioCodecType:(SoraAudioCodecType)audioCodecType
{
    self = [super initWithRole: role
                      clientId: clientId
                     channelId: channelId];
    if (self != nil) {
        self.role = role;
        
    }
    return self;
}

- (SoraMessageType)messageType
{
    return SoraMessageTypeArchiveFinished;
}

@end

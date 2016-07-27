#import <Sora/SoraStreamingMessage.h>

@interface SoraArchiveFinishedResponse : SoraStreamingMessage

@property(nonatomic, readwrite, nullable) NSDate *creationTime;
@property(nonatomic, readwrite, nullable) NSString *filePath;
@property(nonatomic, readwrite, nullable) NSString *fileName;
@property(nonatomic, readwrite) NSUInteger fileSize;
@property(nonatomic, readwrite) SoraVideoCodecType videoCodecType;
@property(nonatomic, readwrite) SoraAudioCodecType audioCodecType;

- (nullable instancetype)initWithRole:(SoraRole)role
                             clientId:(nonnull NSString *)clientId
                            channelId:(nonnull NSString *)channelId
                         creationTime:(nonnull NSDate *)creationTime
                             filePath:(nonnull NSString *)filePath
                             fileName:(nonnull NSString *)fileName
                             fileSize:(NSUInteger)fileSize
                       videoCodecType:(SoraVideoCodecType)videoCodecType
                       audioCodecType:(SoraAudioCodecType)audioCodecType;

@end

#import <Foundation/Foundation.h>
#import <Sora/SoraMessage.h>

@interface SoraConnectRequest : SoraMessage

@property(nonatomic, readwrite) SoraRole role;
@property(nonatomic, readwrite, nonnull) NSString *channelId;
@property(nonatomic, readwrite, nullable) NSString *accessToken;
@property(nonatomic, readwrite) SoraVideoCodecType videoCodecType;
@property(nonatomic, readwrite) SoraAudioCodecType audioCodecType;
@property(nonatomic, readwrite) BOOL isVideoEnabled;
@property(nonatomic, readwrite) BOOL isAudioEnabled;

- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken;
- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken
                       isVideoEnabled:(BOOL)isVideoEnabled
                       videoCodecType:(SoraVideoCodecType)videoCodecType
                       isAudioEnabled:(BOOL)isAudioEnabled
                       audioCodecType:(SoraAudioCodecType)audioCodecType;

@end

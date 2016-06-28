#import "SoraConnectRequest.h"

static NSString * const AccessTokenKey = @"access_token";
static NSString * const ChannelIdKey = @"channel_id";
static NSString * const CodecTypeKey = @"codec_type";
static NSString * const RoleKey = @"role";
static NSString * const TypeKey = @"type";
static NSString * const VideoKey = @"video";

@implementation SoraConnectRequest

- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken
{
    return [self initWithRole: role
                    channelId: channelId
                  accessToken: accessToken
               isVideoEnabled: YES
               videoCodecType: SoraVideoCodecTypeVP8
               isAudioEnabled: YES
               audioCodecType: SoraAudioCodecTypeOpus];
}

- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken
                       isVideoEnabled:(BOOL)isVideoEnabled
                       videoCodecType:(SoraVideoCodecType)videoCodecType
                       isAudioEnabled:(BOOL)isAudioEnabled
                       audioCodecType:(SoraAudioCodecType)audioCodecType
{
    self = [super init];
    if (self != nil) {
        self.role = role;
        self.channelId = channelId;
        self.accessToken = accessToken;
        self.isVideoEnabled = isVideoEnabled;
        self.videoCodecType = videoCodecType;
        self.isAudioEnabled = isAudioEnabled;
        self.audioCodecType = audioCodecType;
    }
    return self;
}

- (SoraMessageType)messageType
{
    return SoraMessageTypeConnect;
}

#pragma mark SoraJSONEncoding

- (void)encodeIntoJSONObject:(nonnull NSMutableDictionary *)dict
{
    dict[ChannelIdKey] = self.channelId;
    if (self.accessToken != nil)
        dict[SoraMessageJSONKeyAccessToken] = self.accessToken;
    
    switch (self.role) {
        case SoraRoleUpstream:
            dict[SoraMessageJSONKeyRole] = SoraMessageJSONValueUpstream;
            break;
        case SoraRoleDownstream:
            dict[SoraMessageJSONKeyRole] = SoraMessageJSONValueDownstream;
            break;
        default:
            NSAssert(NO, @"unknown role");
    }
    
    NSMutableDictionary *videoDict = [[NSMutableDictionary alloc] init];
    switch (self.videoCodecType) {
        case SoraVideoCodecTypeVP8:
            videoDict[SoraMessageJSONKeyCodecType] = @"VP8";
            break;
        case SoraVideoCodecTypeVP9:
            videoDict[SoraMessageJSONKeyCodecType] = @"VP9";
            break;
        case SoraVideoCodecTypeH264:
            videoDict[SoraMessageJSONKeyCodecType] = @"H264";
            break;
        default:
            NSAssert(NO, @"unknown codec type");
    }
    dict[SoraMessageJSONKeyVideo] = videoDict;
}

@end

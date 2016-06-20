#import "SoraRequest.h"

static NSString * const AccessTokenKey = @"access_token";
static NSString * const ChannelIdKey = @"channel_id";
static NSString * const CodecTypeKey = @"codec_type";
static NSString * const RoleKey = @"role";
static NSString * const TypeKey = @"type";
static NSString * const VideoKey = @"video";

@implementation SoraRequest

- (nullable id)initWithRole:(SoraRole)role channelId:(nonnull NSString *)channelId
{
    self = [super init];
    if (self != nil) {
        self.role = role;
        self.channelId = channelId;
        self.accessToken = nil;
        self.codecType = SoraCodecTypeVP9;
    }
    return self;
}

- (nonnull id)JSONObject
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[TypeKey] = @"connect";
    dict[ChannelIdKey] = self.channelId;
    if (self.accessToken != nil)
        dict[AccessTokenKey] = self.accessToken;
    
    switch (self.role) {
        case SoraRoleUpstream:
            dict[RoleKey] = @"upstream";
            break;
        case SoraRoleDownstream:
            dict[RoleKey] = @"downstream";
            break;
        default:
            @throw [NSException
                    exceptionWithName: NSGenericException
                    reason: [NSString stringWithFormat: @"unknown role %lu", (unsigned long)self.role]
                    userInfo: nil];
    }
    
    NSMutableDictionary *videoDict = [[NSMutableDictionary alloc] init];
    switch (self.codecType) {
        case SoraCodecTypeVP8:
            videoDict[CodecTypeKey] = @"VP8";
            break;
        case SoraCodecTypeVP9:
            videoDict[CodecTypeKey] = @"VP9";
            break;
        case SoraCodecTypeH264:
            videoDict[CodecTypeKey] = @"H264";
            break;
        default:
            @throw [NSException
                    exceptionWithName: NSGenericException
                    reason: [NSString stringWithFormat: @"unknown codec type %lu", (unsigned long)self.codecType]
                    userInfo: nil];
    }
    dict[VideoKey] = videoDict;
    
    return dict;
}

@end

#import "SoraMessage.h"
#import "SoraError.h"

NSString * const __nonnull SoraMessageTypeNameConnect = @"connect";
NSString * const __nonnull SoraMessageTypeNameOffer = @"offer";
NSString * const __nonnull SoraMessageTypeNameAnswer = @"answer";
NSString * const __nonnull SoraMessageTypeNameCandidate = @"candidate";
NSString * const __nonnull SoraMessageTypeNameError = @"error";
NSString * const __nonnull SoraMessageTypeNameSignalingConnected = @"signaling.connected";
NSString * const __nonnull SoraMessageTypeNameSignalingUpdated = @"signaling.updated";
NSString * const __nonnull SoraMessageTypeNameSignalingDisconnected = @"signaling.disconnected";
NSString * const __nonnull SoraMessageTypeNameSignalingFailed = @"signaling.failed";
NSString * const __nonnull SoraMessageTypeNameArchiveFinished = @"archive.finished";
NSString * const __nonnull SoraMessageTypeNameArchiveFailed = @"archive.failed";
NSString * const __nonnull SoraMessageTypeNameTransportEncrypted = @"transport.encrypted";

NSString * const __nonnull SoraMessageJSONKeyType = @"type";
NSString * const __nonnull SoraMessageJSONKeyChannelId = @"channel_id";
NSString * const __nonnull SoraMessageJSONKeyClientId = @"client_id";
NSString * const __nonnull SoraMessageJSONKeyRole = @"role";
NSString * const __nonnull SoraMessageJSONKeyAccessToken = @"access_token";
NSString * const __nonnull SoraMessageJSONKeySDP = @"sdp";
NSString * const __nonnull SoraMessageJSONKeyVideo = @"video";
NSString * const __nonnull SoraMessageJSONKeyAudio = @"audio";
NSString * const __nonnull SoraMessageJSONKeyCodecType = @"codec_type";
NSString * const __nonnull SoraMessageJSONKeyCodecName = @"codec_name";
NSString * const __nonnull SoraMessageJSONKeyData = @"data";
NSString * const __nonnull SoraMessageJSONKeyReason = @"reason";
NSString * const __nonnull SoraMessageJSONKeyErrorReason = @"error_reason";
NSString * const __nonnull SoraMessageJSONKeyFailureReason = @"failure_reason";
NSString * const __nonnull SoraMessageJSONKeyMetaData = @"metadata";
NSString * const __nonnull SoraMessageJSONKeyMinites = @"minites";
NSString * const __nonnull SoraMessageJSONKeyChannelConnections = @"channel_connections";
NSString * const __nonnull SoraMessageJSONKeyUpstreamConnections = @"upstream_connections";
NSString * const __nonnull SoraMessageJSONKeyDownstreamConnections = @"downstream_connections";
NSString * const __nonnull SoraMessageJSONKeyCreatedAt = @"created_at";
NSString * const __nonnull SoraMessageJSONKeyFilePath = @"filepath";
NSString * const __nonnull SoraMessageJSONKeyFileName = @"filename";
NSString * const __nonnull SoraMessageJSONKeySize = @"size";
NSString * const __nonnull SoraMessageJSONKeyConfig = @"config";
NSString * const __nonnull SoraMessageJSONKeyICEServers = @"iceServers";
NSString * const __nonnull SoraMessageJSONKeyCredential = @"credential";
NSString * const __nonnull SoraMessageJSONKeyURLs = @"urls";
NSString * const __nonnull SoraMessageJSONKeyUserName = @"username";
NSString * const __nonnull SoraMessageJSONKeyICETransportPolicy = @"iceTransportPolicy";
NSString * const __nonnull SoraMessageJSONKeyICETransports = @"iceTransports";

NSString * const __nonnull SoraMessageJSONValueUpstream = @"upstream";
NSString * const __nonnull SoraMessageJSONValueDownstream = @"downstream";
NSString * const __nonnull SoraMessageJSONValueVP8 = @"VP8";
NSString * const __nonnull SoraMessageJSONValueVP9 = @"VP9";
NSString * const __nonnull SoraMessageJSONValueOPUS = @"OPUS";
NSString * const __nonnull SoraMessageJSONValueRelay = @"relay";

NSString * const __nonnull SoraSessionDescriptionTypeOffer = @"offer";
NSString * const __nonnull SoraSessionDescriptionTypeAnswer = @"answer";
NSString * const __nonnull SoraSessionDescriptionTypePrAnswer = @"pranswer";

@implementation SoraMessage

- (nullable instancetype)init
{
    self = [super init];
    if (self != nil) {
        self.optionalItems = nil;
    }
    return self;
}

- (nullable instancetype)initWithJSONObject:(nonnull NSDictionary *)dict
                                      error:(NSError * _Nullable *_Nullable)error
{
    self = [self init];
    if (self != nil) {
        if (![self decodeWithJSONObject: dict error: error]) {
            return nil;
        }
    }
    return self;
}

- (nullable instancetype)initWithString:(nonnull NSString *)JSONString
                                  error:(NSError * _Nullable *_Nullable)error
{
    NSData *data = [JSONString dataUsingEncoding: NSUTF8StringEncoding];
    if (data == nil) {
        if (error != nil)
            *error = [SoraError stringEncodingError: JSONString];
        return nil;
    }

    id JSON = [NSJSONSerialization JSONObjectWithData: data
                                              options: 0
                                                error: error];
    if (JSON == nil)
        return nil;
    if (![JSON isKindOfClass: [NSDictionary class]]) {
        if (error != nil)
            *error = [[SoraError alloc] initWithCode: SoraErrorCodeInvalidJSONObjectError
                                            userInfo: @{SoraErrorKeyJSONObject:JSON}];
        return nil;
    }
    
    return [self initWithJSONObject: JSON error: error];
}

- (SoraMessageType)messageType
{
    [self doesNotRecognizeSelector: @selector(messageType)];
    return 0;
}

- (nonnull NSString *)messageTypeDescription
{
    switch ([self messageType]) {
        case SoraMessageTypeConnect:
            return SoraMessageTypeNameConnect;
        case SoraMessageTypeOffer:
            return SoraMessageTypeNameOffer;
        case SoraMessageTypeAnswer:
            return SoraMessageTypeNameAnswer;
        case SoraMessageTypeCandidate:
            return SoraMessageTypeNameCandidate;
        case SoraMessageTypeError:
            return SoraMessageTypeNameError;
        case SoraMessageTypeSignalingConnected:
            return SoraMessageTypeNameSignalingConnected;
        case SoraMessageTypeSignalingUpdated:
            return SoraMessageTypeNameSignalingUpdated;
        case SoraMessageTypeSignalingDisconnected:
            return SoraMessageTypeNameSignalingDisconnected;
        case SoraMessageTypeSignalingFailed:
            return SoraMessageTypeNameSignalingFailed;
        case SoraMessageTypeArchiveFinished:
            return SoraMessageTypeNameArchiveFinished;
        case SoraMessageTypeArchiveFailed:
            return SoraMessageTypeNameArchiveFailed;
        case SoraMessageTypeTransportEncrypted:
            return SoraMessageTypeNameTransportEncrypted;
        default:
            NSAssert(NO, @"unknown message type");
    }
}

- (nonnull NSDictionary *)JSONObject
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity: 8];
    [self encodeIntoJSONObject: dict];
    return dict;
}

- (nullable NSString *)messageToSend:(NSError * _Nullable *_Nullable)error
{
    NSDictionary *JSON = [self JSONObject];
    NSData *data = [NSJSONSerialization dataWithJSONObject: JSON
                                                   options: 0
                                                     error: error];
    if (data == nil)
        return nil;
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

#pragma mark SoraJSONEncoding

- (BOOL)decodeWithJSONObject:(nonnull NSDictionary *)dict
                      error:(NSError * _Nullable *_Nullable)error
{
    return YES;
}

- (void)encodeIntoJSONObject:(nonnull NSMutableDictionary *)dict
{
    dict[SoraMessageJSONKeyType] = [self messageTypeDescription];
    if (self.optionalItems != nil) {
        [dict setValuesForKeysWithDictionary: self.optionalItems];
    }
}

@end
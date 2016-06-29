#import <Foundation/Foundation.h>
#import <Sora/RTCSessionDescription.h>

typedef NS_ENUM(NSUInteger, SoraMessageType) {
    SoraMessageTypeConnect,
    SoraMessageTypeOffer,
    SoraMessageTypeAnswer,
    SoraMessageTypeCandidate,
    SoraMessageTypeError,
    SoraMessageTypeSignalingConnected,
    SoraMessageTypeSignalingUpdated,
    SoraMessageTypeSignalingDisconnected,
    SoraMessageTypeSignalingFailed,
    SoraMessageTypeArchiveFinished,
    SoraMessageTypeArchiveFailed,
    SoraMessageTypeTransportEncrypted,
};

typedef NS_ENUM(NSUInteger, SoraRole) {
    SoraRoleUpstream,
    SoraRoleDownstream
};

typedef NS_ENUM(NSUInteger, SoraVideoCodecType) {
    SoraVideoCodecTypeVP8,
    SoraVideoCodecTypeVP9,
    SoraVideoCodecTypeH264
};

typedef NS_ENUM(NSUInteger, SoraAudioCodecType) {
    SoraAudioCodecTypeOpus,
};

typedef NS_ENUM(NSUInteger, SoraFailureReason) {
    SoraFailureReasonDuplicatedChannelId,
    SoraFailureReasonAuthenticationFailure,
    SoraFailureReasonFailureSDPParse,
    SoraFailureReasonUnknownType,
};

extern NSString * const __nonnull SoraMessageTypeNameConnect;
extern NSString * const __nonnull SoraMessageTypeNameOffer;
extern NSString * const __nonnull SoraMessageTypeNameAnswer;
extern NSString * const __nonnull SoraMessageTypeNameCandidate;
extern NSString * const __nonnull SoraMessageTypeNameError;
extern NSString * const __nonnull SoraMessageTypeNameSignalingConnected;
extern NSString * const __nonnull SoraMessageTypeNameSignalingUpdated;
extern NSString * const __nonnull SoraMessageTypeNameSignalingDisconnected;
extern NSString * const __nonnull SoraMessageTypeNameSignalingFailed;
extern NSString * const __nonnull SoraMessageTypeNameArchiveFinished;
extern NSString * const __nonnull SoraMessageTypeNameArchiveFailed;
extern NSString * const __nonnull SoraMessageTypeNameTransportEncrypted;

extern NSString * const __nonnull SoraMessageJSONKeyType;
extern NSString * const __nonnull SoraMessageJSONKeyChannelId;
extern NSString * const __nonnull SoraMessageJSONKeyClientId;
extern NSString * const __nonnull SoraMessageJSONKeyRole;
extern NSString * const __nonnull SoraMessageJSONKeyAccessToken;
extern NSString * const __nonnull SoraMessageJSONKeySDP;
extern NSString * const __nonnull SoraMessageJSONKeyVideo;
extern NSString * const __nonnull SoraMessageJSONKeyAudio;
extern NSString * const __nonnull SoraMessageJSONKeyCodecType;
extern NSString * const __nonnull SoraMessageJSONKeyCodecName;
extern NSString * const __nonnull SoraMessageJSONKeyData;
extern NSString * const __nonnull SoraMessageJSONKeyReason;
extern NSString * const __nonnull SoraMessageJSONKeyErrorReason;
extern NSString * const __nonnull SoraMessageJSONKeyFailureReason;
extern NSString * const __nonnull SoraMessageJSONKeyMetaData;
extern NSString * const __nonnull SoraMessageJSONKeyMinites;
extern NSString * const __nonnull SoraMessageJSONKeyChannelConnections;
extern NSString * const __nonnull SoraMessageJSONKeyUpstreamConnections;
extern NSString * const __nonnull SoraMessageJSONKeyDownstreamConnections;
extern NSString * const __nonnull SoraMessageJSONKeyCreatedAt;
extern NSString * const __nonnull SoraMessageJSONKeyFilePath;
extern NSString * const __nonnull SoraMessageJSONKeyFileName;
extern NSString * const __nonnull SoraMessageJSONKeySize;
extern NSString * const __nonnull SoraMessageJSONValueUpstream;
extern NSString * const __nonnull SoraMessageJSONValueDownstream;
extern NSString * const __nonnull SoraMessageJSONValueVP8;
extern NSString * const __nonnull SoraMessageJSONValueVP9;
extern NSString * const __nonnull SoraMessageJSONValueOPUS;

extern NSString * const __nonnull SoraSessionDescriptionTypeOffer;
extern NSString * const __nonnull SoraSessionDescriptionTypeAnswer;
extern NSString * const __nonnull SoraSessionDescriptionTypePrAnswer;

@protocol SoraJSONEncoding <NSObject>

- (BOOL)decodeWithJSONObject:(nonnull NSDictionary *)dict
                      error:(NSError * _Nullable *_Nullable)error;
- (void)encodeIntoJSONObject:(nonnull NSMutableDictionary *)dict;

@end

/// abstract class
@interface SoraMessage : NSObject <SoraJSONEncoding>

@property(nonatomic, readwrite, nullable) NSDictionary *optionalItems;

- (nullable instancetype)init;
- (nullable instancetype)initWithJSONObject:(nonnull NSDictionary *)dict
                                      error:(NSError * _Nullable *_Nullable)error;
- (nullable instancetype)initWithString:(nonnull NSString *)JSONString
                                  error:(NSError * _Nullable *_Nullable)error;

- (SoraMessageType)messageType;
- (nonnull NSString *)messageTypeDescription;
- (nonnull NSDictionary *)JSONObject;
- (nullable NSString *)messageToSend:(NSError * _Nullable *_Nullable)error;

@end
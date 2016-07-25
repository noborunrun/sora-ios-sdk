#import <Foundation/Foundation.h>
#import <Sora/SoraMessage.h>

/**
 シグナリングの開始を要求するメッセージを表します。
 */
@interface SoraConnectRequest : SoraMessage

/** ピアの役割 */
@property(nonatomic, readwrite) SoraRole role;

/** チャネル ID */
@property(nonatomic, readwrite, nonnull) NSString *channelId;

/** アクセストークン */
@property(nonatomic, readwrite, nullable) NSString *accessToken;

/** ビデオコーデック名。デフォルト値は `SoraVideoCodecTypeVP8` です。 */
@property(nonatomic, readwrite) SoraVideoCodecType videoCodecType;

/** オーディオコーデック名。デフォルト値は `SoraAudioCodecTypeOpus` です。 */
@property(nonatomic, readwrite) SoraAudioCodecType audioCodecType;

/** 映像の可否。デフォルト値は `YES` です。 */ 
@property(nonatomic, readwrite) BOOL isVideoEnabled;

/** 音声の可否。デフォルト値は `YES` です。 */ 
@property(nonatomic, readwrite) BOOL isAudioEnabled;

/**
 メッセージを生成します。

 @param role ピアの役割
 @param channelId チャネル ID
 @param accessToken アクセストークン
 @return 初期化済みのメッセージ
 */
- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken;

/**
 メッセージを生成します。

 @param role ピアの役割
 @param channelId チャネル ID
 @param accessToken アクセストークン
 @param isVideoEnabled 映像の可否
 @param videoCodecType ビデオコーデック名
 @param isAudioEnabled 音声の可否
 @param audioCodecType オーディオコーデック名
 @return 初期化済みのメッセージ
 */
- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId
                          accessToken:(nullable NSString *)accessToken
                       isVideoEnabled:(BOOL)isVideoEnabled
                       videoCodecType:(SoraVideoCodecType)videoCodecType
                       isAudioEnabled:(BOOL)isAudioEnabled
                       audioCodecType:(SoraAudioCodecType)audioCodecType;

@end

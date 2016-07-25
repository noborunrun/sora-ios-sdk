#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Sora/RTCPeerConnection.h>
#import <Sora/RTCPeerConnectionInterface.h>
#import <Sora/RTCPeerConnectionFactory.h>
#import <Sora/RTCMediaConstraints.h>
#import <Sora/RTCFileLogger.h>
#import <Sora/RTCVideoRenderer.h>
#import <Sora/SRWebSocket.h>
#import <Sora/SoraError.h>
#import <Sora/SoraOfferResponse.h>
#import <Sora/SoraConnectRequest.h>
#import <Sora/SoreErrorResponse.h>
#import <Sora/SoraAnswerRequest.h>

@protocol SoraConnectionDelegate;

/** Sora サーバーとの接続状態を表します。 */
typedef NS_ENUM(NSUInteger, SoraConnectionState) {

    /** シグナリング接続中です。 */
    SoraConnectionStateConnecting,
    
    /** シグナリング接続が完了し、シグナリングメッセージの通信が可能です。 */
    SoraConnectionStateOpen,
    
    /** ピア接続中です。 */
    SoraConnectionStatePeerConnecting,
    
    /** ピア接続が完了し、データ通信が可能です。 */
    SoraConnectionStatePeerOpen,
    
    /** シグナリング切断中です。 */
    SoraConnectionStateClosing,
    
    /** シグナリング接続していません。 */
    SoraConnectionStateClosed
};

/**
 `SoraConnection` オブジェクトは Sora サーバーとシグナリング接続を行います。
 Sora サーバーでは、シグナリングは WebSocket で JSON 形式のメッセージを介して行います。
 */
@interface SoraConnection : NSObject

/** Sora サーバーの URL */
@property(nonatomic, readonly, nonnull) NSURL *URL;

/** Sora サーバーとの接続状態 */
@property(nonatomic, readonly) SoraConnectionState state;

/** デリゲート */
@property(nonatomic, weak, readwrite, nullable) id<SoraConnectionDelegate> delegate;

@property(nonatomic, readonly, nonnull) RTCPeerConnectionFactory *peerConnectionFactory;

/**
 ピア接続オブジェクト
 
 @warning このオブジェクトのデリゲートを変更しないでください。
 デリゲートは `SoraConnection` オブジェクトの状態管理に使われます。
 */
@property(nonatomic, readonly, nonnull) RTCPeerConnection *peerConnection;
@property(nonatomic, readonly, nonnull) RTCFileLogger *fileLogger;

/** メディアストリーム (RTCMediaStream オブジェクト) の配列 */
@property(nonatomic, readonly, nonnull) NSArray *remoteStreams;

/** 受信した映像を描画するオブジェクト (RTCVideoRenderer プロトコル) の配列 */
@property(nonatomic, readonly, nonnull) NSArray *remoteVideoRenderers;

/**
 指定のサーバーに接続し、初期化済みの `SoraConnection` オブジェクトを返します。

 @param URL 接続するサーバーの URL
 @param config ピア接続の設定
 @param constraints メディアの制約
 @return 初期化済みの `SoraConnection` オブジェクト
 */
- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
                       configuration:(nullable RTCConfiguration *)config
                         constraints:(nullable RTCMediaConstraints *)constraints;

/**
 指定のサーバーに接続し、初期化済みの `SoraConnection` オブジェクトを返します。

 @param URL 接続するサーバーの URL
 @return 初期化済みの `SoraConnection` オブジェクト
 */
- (nullable instancetype)initWithURL:(nonnull NSURL *)URL;

/**
 サーバーとシグナリング接続を行います。
 
 @param connectRequest connect シグナリングメッセージ
 */
- (void)open:(nonnull SoraConnectRequest *)connectRequest;

/** シグナリング接続を閉じます。 */
- (void)close;

/**
 シグナリングメッセージを送信します。
 
 @param message 送信するシグナリングメッセージ
 */
- (void)sendMessage:(nonnull SoraMessage *)message;

+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration;
+ (nonnull NSArray *)defaultICEServers;
+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints;

- (void)addRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view;
- (void)removeRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view;

@end

/**
 `SoraConnectionDelegate` プロトコルは `SoraConnection` のデリゲートメソッドを定義しています。
 */
@protocol SoraConnectionDelegate <NSObject>

@required

- (void)connection:(nonnull SoraConnection *)connection
didReceiveErrorResponse:(nonnull SoreErrorResponse *)response;
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;

@optional

- (void)connectionDidOpen:(nonnull SoraConnection *)connection;
- (void)connection:(nonnull SoraConnection *)connection stateChanged:(SoraConnectionState)state;
- (void)connection:(nonnull SoraConnection *)connection didReceiveMessage:(nonnull id)message;
- (void)connection:(nonnull SoraConnection *)connection didDiscardMessage:(nonnull id)message;
- (void)connection:(nonnull SoraConnection *)connection didReceiveOfferResponse:(nonnull SoraOfferResponse *)response;
- (void)connection:(nonnull SoraConnection *)connection didReceivePing:(nonnull id)message;
- (nullable id)connection:(nonnull SoraConnection *)connection willSendPong:(nonnull id)message;
- (nullable SoraAnswerRequest *)connection:(nonnull SoraConnection *)connection
                     willSendAnswerRequest:(nonnull SoraAnswerRequest *)request;
- (void)connection:(nonnull SoraConnection *)connection signalingStateChanged:(RTCSignalingState)stateChanged;
- (void)connection:(nonnull SoraConnection *)connection didReceiveWebSocketPong:(nonnull NSData *)pongPayload;
- (void)connection:(nonnull SoraConnection *)connection numberOfDownstreamConnections:(NSUInteger)numStreams;

@end

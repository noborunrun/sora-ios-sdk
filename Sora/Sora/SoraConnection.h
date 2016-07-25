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
 Sora サーバーとシグナリング接続を行います。
 Sora サーバーでは、シグナリングは WebSocket で JSON フォーマットのメッセージを介して行います。
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
 サーバーに接続します。
 
 @param connectRequest connect シグナリングメッセージ
 */
- (void)open:(nonnull SoraConnectRequest *)connectRequest;

/** サーバーとの接続を閉じます。 */
- (void)close;

/**
 シグナリングメッセージを送信します。
 
 @param message 送信するシグナリングメッセージ
 */
- (void)sendMessage:(nonnull SoraMessage *)message;

/**
 ピア接続時に使われるデフォルトの設定を返します。

 @return ピア接続の設定
 */
+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration;

/**
 ピア接続時に使われるデフォルトの ICE サーバー (RTCICEServer) の配列を返します。
 配列に含まれる ICE サーバーは以下の通りです。
 
 - `stun:stun.l.google.com:19302`

 @return ICE サーバーの配列
 */
+ (nonnull NSArray *)defaultICEServers;

/**
 ピア接続時に使われるデフォルトの制約を返します。

 @return ピア接続の制約
 */
+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints;

/**
 `SoraConnection` オブジェクトが管理する映像描画オブジェクトを追加します。
 このオブジェクトはピア接続時に使われるメディアストリームに自動的に追加されます。

 @param view 
 @code [conn addRemoteVideoRenderer: view];
 */
- (void)addRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view;

/**
 `SoraConnection` オブジェクトが管理する映像描画オブジェクトを除去します。
 このオブジェクトはメディアストリームから除去されます。

 */
- (void)removeRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view;

@end

/**
 `SoraConnection` のデリゲートメソッドを定義しています。
 */
@protocol SoraConnectionDelegate <NSObject>

@required

/**
 サーバーからエラーメッセージを受信したときに実行されます。

 @param connection サーバー接続
 @param response エラーメッセージ
 */
- (void)connection:(nonnull SoraConnection *)connection
didReceiveErrorResponse:(nonnull SoreErrorResponse *)response;

/**
 接続時に何らかのエラーが発生したときに実行されます。

 @param connection サーバー接続
 @param error エラー内容
 */
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;

@optional

/**
 シグナリング接続 (WebSocket 接続) が完了したときに実行されます。

 @param connection サーバー接続
 */
- (void)connectionDidOpen:(nonnull SoraConnection *)connection;

/**
 サーバーの接続状態が変更されたときに実行されます。

 @param connection サーバー接続
 @param state 変更後の状態
 */
- (void)connection:(nonnull SoraConnection *)connection stateChanged:(SoraConnectionState)state;

/**
 サーバーから何らかのメッセージを受信したときに実行されます。

 @param connection サーバー接続
 @param message 受信したメッセージ。 NSString もしくは NSData です。
 */
- (void)connection:(nonnull SoraConnection *)connection didReceiveMessage:(nonnull id)message;

/**
 サーバーから受信したメッセージを破棄するときに実行されます。
 JSON 以外のフォーマットのメッセージや、無効なシグナリングメッセージが破棄されます。

 @param connection サーバー接続
 @param message 破棄するメッセージ。 NSString もしくは NSData です。
 */
- (void)connection:(nonnull SoraConnection *)connection didDiscardMessage:(nonnull id)message;

- (void)connection:(nonnull SoraConnection *)connection didReceiveOfferResponse:(nonnull SoraOfferResponse *)response;
- (void)connection:(nonnull SoraConnection *)connection didReceivePing:(nonnull id)message;
- (nullable id)connection:(nonnull SoraConnection *)connection willSendPong:(nonnull id)message;
- (nullable SoraAnswerRequest *)connection:(nonnull SoraConnection *)connection
                     willSendAnswerRequest:(nonnull SoraAnswerRequest *)request;
- (void)connection:(nonnull SoraConnection *)connection signalingStateChanged:(RTCSignalingState)stateChanged;
- (void)connection:(nonnull SoraConnection *)connection didReceiveWebSocketPong:(nonnull NSData *)pongPayload;

/**
 サーバーからダウンストリームの接続数の情報を受信したときに実行されます。

 @param connection サーバー接続
 @param numStreams ダウンストリームの接続数
 */
- (void)connection:(nonnull SoraConnection *)connection numberOfDownstreamConnections:(NSUInteger)numStreams;

@end

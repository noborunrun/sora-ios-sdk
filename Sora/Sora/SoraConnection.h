#import <Foundation/Foundation.h>

#import <Sora/RTCPeerConnection.h>
#import <Sora/RTCPeerConnectionInterface.h>
#import <Sora/RTCPeerConnectionFactory.h>
#import <Sora/RTCMediaConstraints.h>
#import <Sora/RTCFileLogger.h>
#import <Sora/SRWebSocket.h>
#import <Sora/SoraError.h>
#import <Sora/SoraOfferResponse.h>
#import <Sora/SoraConnectRequest.h>
#import <Sora/SoreErrorResponse.h>
#import <Sora/SoraAnswerRequest.h>

@protocol SoraConnectionDelegate;

typedef NS_ENUM(NSUInteger, SoraConnectionState) {
    SoraConnectionStateConnecting,
    SoraConnectionStateOpen,
    SoraConnectionStateClosing,
    SoraConnectionStateClosed
};

@interface SoraConnection : NSObject

@property(nonatomic, readonly, nonnull) NSURL *URL;
@property(nonatomic, readonly) SoraConnectionState state;
@property(nonatomic, weak, readwrite, nullable) id<SoraConnectionDelegate> delegate;
@property(nonatomic, readonly, nonnull) RTCPeerConnectionFactory *peerConnectionFactory;
@property(nonatomic, readonly, nonnull) RTCPeerConnection *peerConnection;
@property(nonatomic, readonly, nonnull) RTCFileLogger *fileLogger;


- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
                       configuration:(nullable RTCConfiguration *)config
                         constraints:(nullable RTCMediaConstraints *)constraints;
- (nullable instancetype)initWithURL:(nonnull NSURL *)URL;

- (void)open:(nonnull SoraConnectRequest *)connectRequest;
- (void)close;

+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration;
+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints;

@end

@protocol SoraConnectionDelegate <NSObject>

@required

- (void)connection:(nonnull SoraConnection *)connection
didReceiveErrorResponse:(nonnull SoreErrorResponse *)response;
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;

@optional

- (void)connectionDidOpen:(nonnull SoraConnection *)connection;
- (void)connection:(nonnull SoraConnection *)connection didReceiveMessage:(nonnull id)message;
- (void)connection:(nonnull SoraConnection *)connection didDiscardMessage:(nonnull id)message;
- (void)connection:(nonnull SoraConnection *)connection didReceiveOfferResponse:(nonnull SoraOfferResponse *)response;
- (void)connection:(nonnull SoraConnection *)connection didReceivePing:(nonnull id)message;
- (nullable SoraAnswerRequest *)connection:(nonnull SoraConnection *)connection
                     willSendAnswerRequest:(nonnull SoraAnswerRequest *)request;
- (void)connection:(nonnull SoraConnection *)connection signalingStateChanged:(RTCSignalingState)stateChanged;

@end

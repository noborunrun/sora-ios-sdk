#import <Foundation/Foundation.h>

#import "RTCPeerConnection.h"
#import "RTCPeerConnectionInterface.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCMediaConstraints.h"
#import "RTCFileLogger.h"
#import "SRWebSocket.h"
#import "SoraError.h"
#import "SoraOfferResponse.h"
#import "SoraConnectRequest.h"
#import "SoreErrorResponse.h"
#import "SoraAnswerRequest.h"

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
- (nullable SoraAnswerRequest *)connection:(nonnull SoraConnection *)connection
                     willSendAnswerRequest:(nonnull SoraAnswerRequest *)request;

@end

#import <Foundation/Foundation.h>

#import "RTCPeerConnection.h"
#import "RTCPeerConnectionInterface.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCMediaConstraints.h"
#import "RTCFileLogger.h"
#import "SRWebSocket.h"
#import "SoraOffer.h"
#import "SoraRequest.h"

@protocol SoraConnectionDelegate;

typedef NS_ENUM(NSUInteger, SoraConnectionState) {
    SoraConnectionStateConnecting,
    SoraConnectionStateOpen,
    SoraConnectionStateClosing,
    SoraConnectionStateClosed
};

typedef NS_ENUM(NSInteger, SoraErrorCode) {
    SoraErrorCodeUnknownTypeError,
    SoraErrorCodeOfferError,
    SoraErrorCodeWebSocketError
};

extern NSString * __nonnull const SoraErrorDomain;

// SoraErrorCodeOfferError
extern NSString * __nonnull const SoraOfferErrorMessageKey;

/// SoraErrorCodeWebSocketError
extern NSString * __nonnull const SoraWebSocketErrorKey;

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

- (void)open:(nonnull SoraRequest *)request;
- (void)close;

+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration;
+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints;

@end

@protocol SoraConnectionDelegate <NSObject>

@optional

- (void)connectionDidOpen:(nonnull SoraConnection *)connection;
- (void)connection:(nonnull SoraConnection *)connection didReceiveMessage:(nonnull id)message;
- (void)connection:(nonnull SoraConnection *)connection didReceiveOffer:(nonnull SoraOffer *)offer;
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;
- (void)connection:(nonnull SoraConnection *)connection;

@end

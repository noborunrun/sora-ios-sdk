#import <Foundation/Foundation.h>

#import "SRWebSocket.h"
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
    SoraErrorCodeWebSocketError
};

extern NSString * __nonnull const SoraErrorDomain;

/// SoraErrorCodeWebSocketError
extern NSString * __nonnull const SoraWebSocketErrorKey;

@interface SoraConnection : NSObject

@property(nonatomic, readonly, nonnull) NSURL *URL;
@property(nonatomic, readonly) SoraConnectionState state;
@property(nonatomic, weak, readwrite, nullable) id<SoraConnectionDelegate> delegate;

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL;

- (void)open:(nonnull SoraRequest *)request;
- (void)close;

@end

@protocol SoraConnectionDelegate <NSObject>

- (void)connectionDidOpen:(nonnull SoraConnection *)connection;
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;
- (void)connection:(nonnull SoraConnection *)connection;

@end

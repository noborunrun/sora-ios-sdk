#import <Foundation/Foundation.h>

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

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL;

@end

@protocol SoraConnectionDelegate <NSObject>

- (void)connectionDidOpen:(nonnull SoraConnection *)connection;
- (void)connection:(nonnull SoraConnection *)connection
  didFailWithError:(nonnull NSError *)error;
- (void)connection:(nonnull SoraConnection *)connection;

@end

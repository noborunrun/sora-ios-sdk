#import "SRWebSocket.h"
#import "SoraConnection.h"
#import "SoraOffer.h"

NSString * const SoraErrorDomain = @"SoraErrorDomain";

NSString * const SoraOfferErrorMessageKey = @"SoraOfferErrorMessageKey";
NSString * const SoraWebSocketErrorKey = @"SoraErrorCodeWebSocketError";

@class SoraConnectingContext;

@interface SoraConnection ()

@property(nonatomic, readwrite, nonnull) NSURL *URL;
@property(nonatomic, readwrite) SoraConnectionState state;
@property(nonatomic, readwrite, nullable) SRWebSocket *webSocket;
@property(nonatomic, readwrite, nullable) SoraConnectingContext *context;

@end

@interface SoraConnectingContext : NSObject <SRWebSocketDelegate>

@property(nonatomic, weak, readwrite, nullable) SoraConnection *conn;
@property(nonatomic, readwrite, nonnull) SoraRequest *request;
@property(nonatomic, readwrite) bool waitsResponse;

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn
                                    request:(nonnull SoraRequest *)request;

@end

@implementation SoraConnection

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
{
    self = [super init];
    if (self != nil) {
        self.URL = URL;
        self.state = SoraConnectionStateClosed;
    }
    return self;
}

- (void)open:(nonnull SoraRequest *)request
{
    self.state = SoraConnectionStateConnecting;
    self.webSocket = [[SRWebSocket alloc] initWithURL: self.URL];
    self.context = [[SoraConnectingContext alloc]
                    initWithConnection: self
                    request: request];
    self.webSocket.delegate = self.context;
    NSLog(@"open WebSocket");
    [self.webSocket open];
}

- (void)close
{
    [self.webSocket close];
}

@end

@implementation SoraConnectingContext

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn
                                    request:(nonnull SoraRequest *)request
{
    self = [self init];
    if (self != nil) {
        self.conn = conn;
        self.request = request;
        self.waitsResponse = false;
    }
    return self;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"WebSocket receive %@", [message description]);
    if (!self.waitsResponse) {
        NSLog(@"received an unexpected message: %@", [message description]);
        return;
    }
    
    NSData *data;
    if ([message isKindOfClass: [NSData class]])
        data = message;
    else if ([message isKindOfClass: [NSString class]]) {
        data = [(NSString *)message dataUsingEncoding: NSUTF8StringEncoding];
        if (data == nil)
            @throw [NSException exceptionWithName: NSGenericException
                                           reason: @"cannot convert received message to UTF-8 bytes"
                                         userInfo: nil];
    } else {
        @throw [NSException exceptionWithName: NSGenericException
                                       reason: @"received message is not kind of NSData or NSString"
                                     userInfo: nil];
    }
    
    if ([self.conn.delegate respondsToSelector: @selector(connection:didReceiveMessage:)]) {
        [self.conn.delegate connection: self.conn
                     didReceiveMessage: message];
    }
    
    NSError *error = nil;
    id JSON = [NSJSONSerialization JSONObjectWithData: data
                                              options: 0
                                                error: &error];
    if (error != nil) {
        @throw error;
    }
    NSLog(@"received message: %@", [JSON description]);
    
    SoraOffer *offer = [[SoraOffer alloc] initWithJSONObject: JSON];
    if (offer == nil) {
        error = [[NSError alloc] initWithDomain: SoraErrorDomain
                                           code: SoraErrorCodeOfferError
                                       userInfo: @{SoraOfferErrorMessageKey: message}];
    }
    NSLog(@"offer object = %@", [offer description]);
    if ([self.conn.delegate respondsToSelector: @selector(connection:didReceiveOffer:)]) {
        [self.conn.delegate connection: self.conn
                       didReceiveOffer: offer];
    }
    
    self.conn.state = SoraConnectionStateOpen;
    self.waitsResponse = false;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"WebSocket opened");
    id obj = [self.request JSONObject];
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject: obj
                                                   options: 0
                                                     error: &error];
    if (error != nil) {
        NSLog(@"JSON serialization failed: %@", [obj description]);
        if ([self.conn.delegate respondsToSelector:
             @selector(connection:didFailWithError:)]) {
            [self.conn.delegate connection: self.conn didFailWithError: error];
        }
    } else {
        NSString *msg = [[NSString alloc] initWithData: data
                                              encoding: NSUTF8StringEncoding];
        NSLog(@"send connecting message: %@", msg);
        self.waitsResponse = true;
        [webSocket send: msg];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket fail");
    self.conn.state = SoraConnectionStateClosed;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket close: %@", reason);
    self.conn.state = SoraConnectionStateClosed;
}

//- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

@end

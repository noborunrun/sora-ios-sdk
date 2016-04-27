#import "SRWebSocket.h"
#import "SoraConnection.h"

NSString * const SoraErrorDomain = @"SoraErrorDomain";

NSString * const SoraWebSocketErrorKey = @"SoraErrorCodeWebSocketError";

@interface SoraConnection ()

@property(nonatomic, readwrite, nonnull) NSURL *URL;
@property(nonatomic, readwrite) SoraConnectionState state;
@property(nonatomic, readwrite, nullable) SRWebSocket *webSocket;
@property(nonatomic, readwrite, nullable) SoraRequest *request;

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
    self.request = request;
    self.webSocket = [[SRWebSocket alloc] initWithURL: self.URL];
    self.webSocket.delegate = self;
    NSLog(@"open WebSocket");
    [self.webSocket open];
}

- (void)close
{
    [self.webSocket close];
}

#pragma mark SRWebSocket Delegate

// TODO
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"WebSocket receive %@", [message description]);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"WebSocket open");
    self.state = SoraConnectionStateOpen;
    id obj = [self.request JSONObject];
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject: obj
                                                   options: 0
                                                     error: &error];
    if (error != nil) {
        if ([self.delegate respondsToSelector:
             @selector(connection:didFailWithError:)]) {
            [self.delegate connection: self didFailWithError: error];
        }
    } else {
        NSLog(@"send offer %@", [obj description]);
        [webSocket send: [[NSString alloc] initWithData: data
                                               encoding: NSUTF8StringEncoding]];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket fail");
    self.state = SoraConnectionStateClosed;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket close: %@", reason);
    self.state = SoraConnectionStateClosed;
}

//- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

@end

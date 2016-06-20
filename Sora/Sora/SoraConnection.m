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
@property(nonatomic, readwrite, nonnull) RTCPeerConnectionFactory *peerConnectionFactory;
@property(nonatomic, readwrite, nonnull) RTCPeerConnection *peerConnection;
@property(nonatomic, readwrite, nonnull) RTCFileLogger *fileLogger;

@property(nonatomic, readwrite, nullable) SRWebSocket *webSocket;
@property(nonatomic, readwrite, nullable) SoraConnectingContext *context;

@end

@interface SoraConnectingContext : NSObject <SRWebSocketDelegate, RTCPeerConnectionDelegate>

@property(nonatomic, weak, readwrite, nullable) SoraConnection *conn;
@property(nonatomic, readwrite, nullable) SoraRequest *request;
@property(nonatomic, readwrite) bool waitsResponse;

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn;

@end

@implementation SoraConnection

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
                       configuration:(nullable RTCConfiguration *)config
                         constraints:(nullable RTCMediaConstraints *)constraints
{
    self = [super init];
    if (self != nil) {
        [RTCPeerConnectionFactory initializeSSL];
        self.URL = URL;
        self.state = SoraConnectionStateClosed;
        self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
        self.context = [[SoraConnectingContext alloc] initWithConnection: self];
        if (config == nil) {
            config = [[self class] defaultPeerConnectionConfiguration];
        }
        if (constraints == nil) {
            constraints = [[self class] defaultPeerConnectionConstraints];
        }
        self.peerConnection = [self.peerConnectionFactory
                               peerConnectionWithConfiguration: config
                               constraints: constraints
                               delegate: self.context];
        self.fileLogger = [[RTCFileLogger alloc] init];
        [self.fileLogger start];
    }
    return self;
}

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
{
    return [self initWithURL: URL configuration: nil constraints: nil];
}

- (void)open:(nonnull SoraRequest *)request
{
    self.state = SoraConnectionStateConnecting;
    self.context.request = request;
    self.webSocket = [[SRWebSocket alloc] initWithURL: self.URL];
    self.webSocket.delegate = self.context;
    NSLog(@"open WebSocket");
    [self.webSocket open];
}

- (void)close
{
    [self.webSocket close];
}

+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration
{
    return [[RTCConfiguration alloc] init];
}

+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints
{
    return [[RTCMediaConstraints alloc] init];
}

@end

@implementation SoraConnectingContext

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn
{
    self = [self init];
    if (self != nil) {
        self.conn = conn;
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
    NSAssert(self.request != nil, @"request is required");
    
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

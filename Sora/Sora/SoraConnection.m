#import "RTCICEServer.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
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

@interface SoraConnectingContext : NSObject <SRWebSocketDelegate, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

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

#pragma mark WebSocket Delegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"WebSocket receive %@", [message description]);
    if (!self.waitsResponse) {
        NSLog(@"received an unexpected message: %@", [message description]);
        return;
    }
    
    if (![message isKindOfClass: [NSString class]]) {
        @throw [NSException exceptionWithName: NSGenericException
                                       reason: @"received message (NSData) must be NSString"
                                     userInfo: nil];
    }

    NSData *data = [(NSString *)message dataUsingEncoding: NSUTF8StringEncoding];
    if (data == nil) {
        @throw [NSException exceptionWithName: NSGenericException
                                       reason: @"cannot convert received message to UTF-8 bytes"
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
        [self.conn.delegate connection: self.conn didReceiveOffer: offer];
    }
    
    // state
    NSLog(@"send answer");
    message = offer.SDP;
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType: @"offer"
                                  sdp: message];
    NSLog(@"SDP = %@", [sdp description]);
    [self.conn.peerConnection setRemoteDescriptionWithDelegate: self
                                            sessionDescription: sdp];
    [self.conn.peerConnection createAnswerWithDelegate: self
                                           constraints: nil];
    
    // TODO
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

#pragma mark Session Description Delegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error
{
    NSLog(@"create SDP");
    if (error != nil) {
        NSLog(@"error: %@: %@", error.domain, [error.userInfo description]);
    } else
        NSLog(@"%@", sdp.description);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error
{
    NSLog(@"set SDP");
    if (error != nil) {
        NSLog(@"error: %@: %@", error.domain, [error.userInfo description]);
    }
}

#pragma mark Peer Connection Delegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged
{
    NSLog(@"peerConnection:signalingStateChanged:");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream
{
    NSLog(@"peerConnection:addedStream:");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream
{
    NSLog(@"peerConnection:removedStream:");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate
{
    NSLog(@"peerConnection:gotICECandidate:");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState
{
    NSLog(@"peerConnection:iceConnectionChanged:");

}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState
{
    NSLog(@"peerConnection:iceGatheringChanged:");
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
    NSLog(@"peerConnectionOnRenegotiationNeeded");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel
{
    NSLog(@"peerConnection:didOpenDataChannel:");
}

@end

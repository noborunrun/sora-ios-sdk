#import "RTCICECandidate.h"
#import "RTCICEServer.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCMediaStream.h"
#import "RTCVideoTrack.h"
#import "SRWebSocket.h"
#import "SoraConnection.h"
#import "SoraOfferResponse.h"
#import "SoraError.h"
#import "SoraCandidateRequest.h"

@class SoraConnectingContext;

@interface SoraConnection ()

@property(nonatomic, readwrite, nonnull) NSURL *URL;
@property(nonatomic, readwrite) SoraConnectionState state;
@property(nonatomic, readwrite, nonnull) RTCPeerConnectionFactory *peerConnectionFactory;
@property(nonatomic, readwrite, nonnull) RTCPeerConnection *peerConnection;
@property(nonatomic, readwrite, nonnull) RTCFileLogger *fileLogger;
@property(nonatomic, readwrite, nonnull) NSMutableArray *remoteStreams;
@property(nonatomic, readwrite, nonnull) NSMutableArray *remoteVideoRenderers;

@property(nonatomic, readwrite, nullable) SRWebSocket *webSocket;
@property(nonatomic, readwrite, nullable) SoraConnectingContext *context;

@end

typedef NS_ENUM(NSUInteger, SoraConnectingContextState) {
    SoraConnectingContextStateClosed,
    SoraConnectingContextStateOpen,
    SoraConnectingContextStateConnecting,
    SoraConnectingContextStateCreatingAnswer,
    SoraConnectingContextStateSendingAnswer,
    SoraConnectingContextStatePeerOpen,
};

@interface SoraConnectingContext : NSObject <SRWebSocketDelegate, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

@property(nonatomic, weak, readwrite, nullable) SoraConnection *conn;
@property(nonatomic, readwrite, nullable) SoraConnectRequest *connectRequest;
@property(nonatomic, readwrite) SoraConnectingContextState state;
@property(nonatomic, readwrite) SoraAnswerRequest *answerRequest;

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn;
- (nonnull NSString *)stateDescription;

@end

@implementation SoraConnection

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
                       configuration:(nullable RTCConfiguration *)config
                         constraints:(nullable RTCMediaConstraints *)constraints
{
    self = [super init];
    if (self != nil) {
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
        [config setIceServers: [[self class] defaultICEServers]];
        
        self.peerConnection = [self.peerConnectionFactory
                               peerConnectionWithConfiguration: config
                               constraints: constraints
                               delegate: self.context];
        self.fileLogger = [[RTCFileLogger alloc] init];
        [self.fileLogger start];
        self.remoteStreams = [[NSMutableArray alloc] init];
        self.remoteVideoRenderers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
{
    return [self initWithURL: URL configuration: nil constraints: nil];
}

- (void)setState:(SoraConnectionState)state
{
    _state = state;
    if ([self.delegate respondsToSelector: @selector(connection:stateChanged:)]) {
        [self.delegate connection: self stateChanged: state];
    }
}

- (void)open:(nonnull SoraConnectRequest *)connectRequest
{
    self.state = SoraConnectionStateConnecting;
    self.context.connectRequest = connectRequest;
    self.webSocket = [[SRWebSocket alloc] initWithURL: self.URL];
    self.webSocket.delegate = self.context;
    NSLog(@"open WebSocket");
    [self.webSocket open];
}

- (void)close
{
    [self.webSocket close];
}

- (void)sendMessage:(nonnull SoraMessage *)message
{
    NSError *error;
    NSString *msg = [message messageToSend: &error];
    if (msg == nil) {
        [self.delegate connection: self didFailWithError: error];
    } else {
        NSLog(@"send message %@", msg);
        [self.webSocket send: msg];
    }
}

+ (nonnull RTCConfiguration *)defaultPeerConnectionConfiguration
{
    return [[RTCConfiguration alloc] init];
}

+ (nonnull NSArray *)defaultICEServers
{
    NSURL *stun = [[NSURL alloc] initWithString: @"stun:stun.l.google.com:19302"];
    NSAssert(stun != nil, @"failed generating stun server URL object");
    return @[[[RTCICEServer alloc] initWithURI: stun username: @"" password: @""]];
}

+ (nonnull RTCMediaConstraints *)defaultPeerConnectionConstraints
{
    return [[RTCMediaConstraints alloc] init];
}

- (void)addRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view
{
    [(NSMutableArray *)self.remoteVideoRenderers addObject: view];
    for (RTCMediaStream *stream in self.remoteStreams) {
        for (RTCVideoTrack *track in stream.videoTracks) {
            [track addRenderer: view];
        }
    }
}

- (void)removeRemoteVideoRenderer:(nonnull id<RTCVideoRenderer>)view
{
    [(NSMutableArray *)self.remoteVideoRenderers removeObject: view];
    for (RTCMediaStream *stream in self.remoteStreams) {
        for (RTCVideoTrack *track in stream.videoTracks) {
            [track removeRenderer: view];
        }
    }
}

@end

@implementation SoraConnectingContext

- (nullable instancetype)initWithConnection:(nullable SoraConnection *)conn
{
    self = [self init];
    if (self != nil) {
        self.conn = conn;
        self.state = SoraConnectingContextStateClosed;
    }
    return self;
}

- (nonnull NSString *)stateDescription {
    switch (self.state) {
        case SoraConnectingContextStateClosed:
            return @"Closed";
            
        case SoraConnectingContextStateOpen:
            return @"Open";
            
        case SoraConnectingContextStateConnecting:
            return @"Connecting";
            
        case SoraConnectingContextStateCreatingAnswer:
            return @"CreatingAnswer";
            
        case SoraConnectingContextStateSendingAnswer:
            return @"SendingAnswer";
            
        case SoraConnectingContextStatePeerOpen:
            return @"PeerOpen";
            
        default:
            NSAssert(NO, @"error");
            break;
    }
}

#pragma mark WebSocket Delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSAssert(self.connectRequest != nil, @"request is required");
    
    self.state = SoraConnectingContextStateOpen;
    NSLog(@"WebSocket opened");
    if ([self.conn.delegate respondsToSelector: @selector(connectionDidOpen:)]) {
        [self.conn.delegate connectionDidOpen: self.conn];
    }
    
    id obj = [self.connectRequest JSONObject];
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject: obj
                                                   options: 0
                                                     error: &error];
    if (error != nil) {
        NSLog(@"JSON serialization failed: %@", [obj description]);
        [self.conn.delegate connection: self.conn didFailWithError: error];
    } else {
        NSString *msg = [[NSString alloc] initWithData: data
                                              encoding: NSUTF8StringEncoding];
        NSLog(@"send connecting message: %@", msg);
        self.state = SoraConnectingContextStateConnecting;
        self.conn.state = SoraConnectionStatePeerConnecting;
        [webSocket send: msg];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSError *error = nil;
    
    NSLog(@"WebSocket receive %@", [message description]);
    if ([self.conn.delegate respondsToSelector: @selector(connection:didReceiveMessage:)]) {
        [self.conn.delegate connection: self.conn didReceiveMessage: message];
    }
    
    if (![message isKindOfClass: [NSString class]]) {
        error = [[SoraError alloc] initWithCode: SoraErrorCodeBinaryMessageError
                                       userInfo: @{SoraErrorKeyData:message}];
        [self.conn.delegate connection: self.conn didFailWithError: error];
        return;
    }
    
    NSData *data = [(NSString *)message dataUsingEncoding: NSUTF8StringEncoding];
    if (data == nil) {
        error = [SoraError stringEncodingError: message];
        [self.conn.delegate connection: self.conn didFailWithError: error];
        return;
    }
    
    id JSON = [NSJSONSerialization JSONObjectWithData: data
                                              options: 0
                                                error: &error];
    if (JSON == nil) {
        if (error != nil) {
            [self.conn.delegate connection: self.conn didFailWithError: error];
        }
        return;
    }
    NSLog(@"received message: %@", [JSON description]);
    
    NSString *type = JSON[SoraMessageJSONKeyType];
    if (type == nil || ![type isKindOfClass: [NSString class]]) {
        if (error != nil) {
            error = [SoraError JSONKeyNotFoundError: SoraMessageJSONKeyType];
            [self.conn.delegate connection: self.conn didFailWithError: error];
        }
        return;
    } else if ([type isEqualToString: SoraMessageTypeNamePing]) {
        NSLog(@"receive ping");
        if ([self.conn.delegate respondsToSelector: @selector(connection:didReceivePing:)]) {
            [self.conn.delegate connection: self.conn didReceivePing: message];
        }
        NSString *pong = @"{\"type\":\"pong\"}";
        if ([self.conn.delegate respondsToSelector: @selector(connection:willSendPong:)]) {
            id newPong = [self.conn.delegate connection: self.conn willSendPong: pong];
            if (newPong != nil)
                pong = newPong;
        }
        [self.conn.webSocket send: pong];
        return;
    } else if ([type isEqualToString: SoraMessageTypeNameStats]) {
        id value;
        if ((value = JSON[SoraMessageJSONKeyDownstreamConnections]) != nil) {
            if (![value isKindOfClass: [NSNumber class]]) {
                NSLog(@"value of %@ must be number", SoraMessageJSONKeyDownstreamConnections);
                return;
            }
            NSUInteger uintVal = [value unsignedIntegerValue];
            if ([self.conn.delegate respondsToSelector: @selector(connection:numberOfDownstreamConnections:)]) {
                [self.conn.delegate connection: self.conn numberOfDownstreamConnections: uintVal];
            }
            
            if (self.state == SoraConnectingContextStateSendingAnswer) {
                self.state = SoraConnectingContextStatePeerOpen;
                self.conn.state = SoraConnectionStatePeerOpen;
            }
            return;
        }
    }
    
    switch (self.state) {
        case SoraConnectingContextStateConnecting: {
            NSLog(@"SoraConnectingContextStateConnecting");
            SoraOfferResponse *offer = [[SoraOfferResponse alloc] initWithString: message
                                                                           error: &error];
            if (offer == nil) {
                NSLog(@"offer error = %@", [error description]);
                [self.conn.delegate connection: self.conn didFailWithError: error];
                return;
            }
            NSLog(@"offer object = %@", [offer description]);
            
            // set config
            if (offer.config != nil) {
                RTCConfiguration *config = [[self.conn class] defaultPeerConnectionConfiguration];
                
                NSString *value;
                if ((value = offer.config[SoraMessageJSONKeyICETransportPolicy]) != nil) {
                    if ([value isEqualToString: SoraMessageJSONValueRelay])
                        config.iceTransportsType = kRTCIceTransportsTypeRelay;
                }

                NSArray *serverConfigs = offer.config[SoraMessageJSONKeyICEServers];
                if (serverConfigs != nil) {
                    NSMutableArray *servers = [[NSMutableArray alloc] init];
                    for (NSDictionary *serverConfig in serverConfigs) {
                        NSString *user = serverConfig[SoraMessageJSONKeyUserName];
                        NSString *cred = serverConfig[SoraMessageJSONKeyCredential];
                        for (NSString *s in serverConfig[SoraMessageJSONKeyURLs]) {
                            NSURL *URL = [[NSURL alloc] initWithString: s];
                            RTCICEServer *server = [[RTCICEServer alloc] initWithURI: URL
                                                                            username: user
                                                                            password: cred];
                            NSLog(@"ICE server = %@", [server description]);
                            [servers addObject: server];
                        }
                    }
                    config.iceServers = servers;
                }

                [self.conn.peerConnection setConfiguration: config];
            }
            
            if ([self.conn.delegate respondsToSelector: @selector(connection:didReceiveOfferResponse:)]) {
                [self.conn.delegate connection: self.conn didReceiveOfferResponse: offer];
            }
            
            // state
            NSLog(@"send answer");
            self.state = SoraConnectingContextStateCreatingAnswer;
            [self.conn.peerConnection setRemoteDescriptionWithDelegate: self
                                                    sessionDescription: [offer sessionDescription]];
            [self.conn.peerConnection createAnswerWithDelegate: self
                                                   constraints: nil];
            break;
        }
            
        case SoraConnectingContextStateSendingAnswer: {
            // TODO:
            break;
        }
            
        default:
            // discard
            if ([self.conn.delegate respondsToSelector: @selector(connection:didDiscardMessage:)])
                [self.conn.delegate connection: self.conn didDiscardMessage: message];
            break;
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket fail");
    self.conn.state = SoraConnectionStateClosed;
    self.state = SoraConnectingContextStateClosed;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket close: %@", reason);
    self.conn.state = SoraConnectionStateClosed;
    self.state = SoraConnectingContextStateClosed;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSLog(@"WebSocket received pong");
    if ([self.conn.delegate respondsToSelector: @selector(connection:didReceiveWebSocketPong:)]) {
        [self.conn.delegate connection: self.conn didReceiveWebSocketPong: pongPayload];
    }
}

#pragma mark Session Description Delegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error
{
    NSLog(@"create SDP (%@)", [self stateDescription]);
    if (error != nil) {
        NSLog(@"error: %@: %@", error.domain, [error.userInfo description]);
    } else
        NSLog(@"%@", sdp.description);
    switch (self.state) {
        case SoraConnectingContextStateCreatingAnswer: {
            self.state = SoraConnectingContextStateSendingAnswer;
            self.answerRequest = [[SoraAnswerRequest alloc] initWithSDP: sdp.description];
            if ([self.conn.delegate respondsToSelector: @selector(connection:willSendAnswerRequest:)]) {
                SoraAnswerRequest *new = [self.conn.delegate connection: self.conn
                                                  willSendAnswerRequest: self.answerRequest];
                if (new != nil)
                    self.answerRequest = new;
            }

            [self.conn.peerConnection setLocalDescriptionWithDelegate: self
                                                   sessionDescription: [self.answerRequest sessionDescription]];
            NSError *error;
            NSString *msg = [self.answerRequest messageToSend: &error];
            NSLog(@"send msg = %@", msg);
            if (msg == nil) {
                [self.conn.delegate connection: self.conn didFailWithError: error];
            }
            [self.conn.webSocket send: msg];
            break;
        }
        default:
            NSAssert(NO, @"invalid state");
            break;
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error
{
    NSLog(@"set SDP (%@)", [self stateDescription]);
    if (error != nil) {
        NSLog(@"error: %@: %@", error.domain, [error.userInfo description]);
    }
    // TODO: error handling
    switch (self.state) {
        case SoraConnectingContextStateCreatingAnswer:
            break;
            
        case SoraConnectingContextStateSendingAnswer:
            break;
            
        default:
            NSAssert(NO, @"invalid state: %@", [self stateDescription]);
            break;
    }
}

#pragma mark Peer Connection Delegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged
{
    NSLog(@"peerConnection:signalingStateChanged: state %d", stateChanged);
    if ([self.conn.delegate respondsToSelector: @selector(connection:signalingStateChanged:)]) {
        [self.conn.delegate connection: self.conn signalingStateChanged: stateChanged];
    }
    if (stateChanged == RTCSignalingClosed) {
        [self.conn close];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream
{
    NSLog(@"peerConnection:addedStream:");
    [(NSMutableArray *)self.conn.remoteStreams addObject: stream];
    for (id<RTCVideoRenderer> view in self.conn.remoteVideoRenderers) {
        RTCVideoTrack *track = stream.videoTracks[0];
        [track addRenderer: view];
        [track setEnabled: YES];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream
{
    NSLog(@"peerConnection:removedStream:");
    [(NSMutableArray *)self.conn.remoteStreams removeObject: stream];
    for (id<RTCVideoRenderer> view in self.conn.remoteVideoRenderers) {
        for (RTCVideoTrack *track in stream.videoTracks) {
            [track removeRenderer: view];
        }
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate
{
    NSLog(@"peerConnection:gotICECandidate: %@", [candidate description]);
    [peerConnection addICECandidate: candidate];
    
    SoraCandidateRequest *request = [[SoraCandidateRequest alloc] initWithCandidate: candidate.sdp];
    [self.conn sendMessage: request];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState
{
    NSLog(@"peerConnection:iceConnectionChanged: state %d", newState);
    if (newState == RTCICEConnectionFailed) {
        NSError *error = [[SoraError alloc] initWithCode: SoraErrorCodeICEConnectionError
                                                userInfo: nil];
        [self.conn.delegate connection: self.conn didFailWithError: error];
    }
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

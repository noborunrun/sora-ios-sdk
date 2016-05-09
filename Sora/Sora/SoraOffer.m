#import "SoraOffer.h"

static NSString * const ClientIdKey = @"client_id";
static NSString * const SDPKey = @"sdp";
static NSString * const TypeKey = @"type";

@interface SoraOffer ()

@property(nonatomic, readwrite, nonnull) NSString *clientId;
@property(nonatomic, readwrite, nonnull) NSString *SDP;

@end

@implementation SoraOffer

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                      SDP:(nonnull NSString *)SDP
{
    self = [super init];
    if (self != nil) {
        self.clientId = clientId;
        self.SDP = SDP;
    }
    return self;
}

- (nullable instancetype)initWithJSONObject:(nonnull id)JSONObject
{
    if (![JSONObject isKindOfClass: [NSDictionary class]])
        return nil;
    
    NSDictionary *dict = (NSDictionary *)JSONObject;
    NSString *cliendId = dict[ClientIdKey];
    NSString *SDP = dict[SDPKey];
    if (![dict[TypeKey] isEqualToString: @"offer"] || cliendId != nil || SDP != nil)
        return nil;
    
    return [self initWithClientId: cliendId SDP: SDP];
}

@end

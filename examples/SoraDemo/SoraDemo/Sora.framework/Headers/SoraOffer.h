#import <Foundation/Foundation.h>

@interface SoraOffer : NSObject

@property(nonatomic, readonly, nonnull) NSString *clientId;
@property(nonatomic, readonly, nonnull) NSString *SDP;

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                      SDP:(nonnull NSString *)SDP;
- (nullable instancetype)initWithJSONObject:(nonnull id)JSONObject;

@end
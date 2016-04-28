#import <Foundation/Foundation.h>

@interface SoraOffer : NSObject

@property(nonatomic, readonly, nonnull) NSString *clientId;
@property(nonatomic, readonly, nonnull) NSString *SDPMessage;

- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                               SDPMessage:(nonnull NSString *)SDPMessage;

@end
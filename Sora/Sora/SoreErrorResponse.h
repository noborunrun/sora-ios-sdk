#import <Sora/SoraMessage.h>

@interface SoreErrorResponse : SoraMessage

@property(nonatomic, readwrite, nonnull) NSString *reason;
@property(nonatomic, readwrite, nullable) NSString *verboseReason;

- (nonnull instancetype)initWithReason:(nonnull NSString *)reason
                         verboseReason:(nullable NSString *)verboseReason;

@end

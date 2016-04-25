#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SoraRole) {
    Upstream,
    Downstream
};

typedef NS_ENUM(NSUInteger, SoraCodecType) {
    SoraCodecTypeVP8,
    SoraCodecTypeVP9,
    SoraCodecTypeH264
};

@interface SoraRequest : NSObject

@property(nonatomic, readwrite) SoraRole role;
@property(nonatomic, readwrite, nonnull) NSString *channelId;
@property(nonatomic, readwrite, nullable) NSString *accessToken;
@property(nonatomic, readwrite) SoraCodecType codecType;

- (nullable instancetype)initWithRole:(SoraRole)role
                            channelId:(nonnull NSString *)channelId;

@end

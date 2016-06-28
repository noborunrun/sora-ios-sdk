#import "SoraArchiveFailedResponse.h"

@implementation SoraArchiveFailedResponse

- (SoraMessageType)messageType
{
    return SoraMessageTypeArchiveFailed;
}

@end
#import <XCTest/XCTest.h>
#import <Sora/Sora.h>

@interface TestSoraConnectionDelegate : NSObject <SoraConnectionDelegate>

@end

@implementation TestSoraConnectionDelegate

- (void)connection:(SoraConnection *)connection didFailWithError:(NSError *)error
{
    
}

- (void)connection:(SoraConnection *)connection didReceiveErrorResponse:(SoreErrorResponse *)response
{
    
}

- (void)connection:(SoraConnection *)connection didReceiveOfferResponse:(SoraOfferResponse *)response
{
    NSLog(@"didReceiveOffer: %@", [response description]);
}

@end

@interface SoraTests : XCTestCase

@property (nonatomic, readwrite, nullable) SoraConnection *conn;
@property (nonatomic, readwrite, nullable) TestSoraConnectionDelegate *delegate;

@end

@implementation SoraTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSURL *URL = [[NSURL alloc] initWithString: @"ws://127.0.0.1:5000/signaling"];
    NSLog(@"URL = %@", [URL description]);
    self.conn = [[SoraConnection alloc] initWithURL: URL];
    self.delegate = [[TestSoraConnectionDelegate alloc] init];
    self.conn.delegate = self.delegate;
    [self.conn open: [[SoraConnectRequest alloc] initWithRole: SoraRoleDownstream
                                                    channelId: @"test"
                                                  accessToken: nil]];
    // delegate
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

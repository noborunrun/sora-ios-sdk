#import <XCTest/XCTest.h>
#import <Sora/Sora.h>

@interface SoraTests : XCTestCase

@property (nonatomic, readwrite, nullable) SoraConnection *conn;

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
    [self.conn open: [[SoraRequest alloc] initWithRole: SoraRoleDownstream
                                             channelId: @"test"]];
    // delegate
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

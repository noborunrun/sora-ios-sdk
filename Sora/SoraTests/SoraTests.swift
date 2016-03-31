import XCTest
@testable import Sora

class SoraTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var connection: Connection?
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        print("test example")
        let url = NSURL(string: "ws://127.0.0.1:5000/signaling")
        print("url = ", url)
        var conn = Sora.Connection(URL: url!)
        conn.connect(Sora.Request(role: .Downstream, channelId: "test"),
                     handle: { (offer) in print(offer) })
        self.connection = conn
        print("end connect")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

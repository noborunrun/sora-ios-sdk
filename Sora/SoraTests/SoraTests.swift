import XCTest
import WebRTC
@testable import Sora

class SoraTests: XCTestCase {
    
    var conn: Connection!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        conn = Sora.Connection(URL: NSURL(string: "ws://127.0.0.1:5000/signaling")!)
        conn.connect { (error) in
            if let error = error {
                print("signaling connecting is failed: ", error)
            } else {
                print("signaling connection is open")
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

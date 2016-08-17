import XCTest
import WebRTC
@testable import Sora

class SoraConnectionTestDelegate: ConnectionDelegate {
    
    func didFail(connection: Connection, error: NSError) {
        
    }
    
    func didChangeState(connection: Connection, state: Connection.State) {
        
    }
    
    func didSendSignalingConnect(connection: Connection, message: Signaling.Connect) {
        
    }
    
    func didReceiveSignalingOffer(connection: Connection, message: Signaling.Offer) {
        
    }
    
    func didSendSignalingAnswer(connection: Connection, message: Signaling.Answer) {
    
    }
    
    func didSendCandidate(connection: Connection, candidate: RTCIceCandidate) {
        
    }

}

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
        conn = Connection(URL: NSURL(string: "ws://127.0.0.1:5000/signaling")!,
                          config: nil, constraints: nil)
        conn.delegate = SoraConnectionTestDelegate()
        let message = Signaling.Connect(role: Signaling.Role.Downstream,
                                        channelId: "sora",
                                        accessToken: nil)
        conn.open(message)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

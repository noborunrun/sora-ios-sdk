import Foundation

public class Event {
    
    public enum EventType: String {
        case WebSocket
        case Signaling
        case PeerConnection
        case VideoRenderer
    }
    
    public enum Marker {
        case Atomic
        case Start
        case End
    }
    
    public var type: EventType
    public var comment: String
    public var date: Date
    
    public init(type: EventType, comment: String, date: Date = Date()) {
        self.type = type
        self.comment = comment
        self.date = date
    }
    
}

public class EventLog {
    
    public var events: [Event] = []
    public var isEnabled: Bool = true
    public var limit: Int? = nil
    
    public func clear() {
        events = []
    }
    
    public func mark(event: Event) {
        if isEnabled {
            if let limit = limit {
                if limit < events.count {
                    events.removeFirst()
                }
            }
            events.append(event)
            onMarkHandler?(event)
        }
    }

    var onMarkHandler: ((Event) -> Void)?
    
    public func onMark(handler: @escaping (Event) -> Void) {
        onMarkHandler = handler
    }
    
}

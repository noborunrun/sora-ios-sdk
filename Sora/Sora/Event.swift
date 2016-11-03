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
    
    public var description: String {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let desc = String(format: "[%@] %@: %@",
                              formatter.string(from: date),
                              type.rawValue, comment)
            return desc
        }
    }
    
}

public class EventLog {
    
    public var events: [Event] = []
    public var isEnabled: Bool = true
    public var limit: Int? = nil
    public var debugMode: Bool = false
    
    public func clear() {
        events = []
    }
    
    public func mark(event: Event) {
        if isEnabled {
            if debugMode {
                print(event.description)
            }
            if let limit = limit {
                if limit < events.count {
                    events.removeFirst()
                }
            }
            events.append(event)
            onMarkHandler?(event)
        }
    }
    
    public func markFormat(type: Event.EventType,
                           format: String,
                           arguments: CVarArg...) {
        let comment = String(format: format, arguments: arguments)
        let event = Event(type: type, comment: comment)
        mark(event: event)
    }
    
    var onMarkHandler: ((Event) -> Void)?
    
    public func onMark(handler: @escaping (Event) -> Void) {
        onMarkHandler = handler
    }

}

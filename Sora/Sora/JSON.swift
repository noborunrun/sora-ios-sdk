import Foundation

struct JSONBuilder {
    
    var values: [String: AnyObject]
    
    func generate() -> String {
        return try! String(data: NSJSONSerialization.dataWithJSONObject(self.values,
            options: NSJSONWritingOptions(rawValue: 0)),
                           encoding: NSUTF8StringEncoding)!
    }
    
}

/*
public protocol JSONEncodable {
    
    func JSONString() -> String
    
}

func CreateJSONString(obj: AnyObject) -> String {
    return try! String(data: NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0)),
                       encoding: NSUTF8StringEncoding)!
}


*/
import Foundation

struct JSONBuilder {
    
    var values: [String: AnyObject]
    
    func generate() -> String {
        return try! String(data: JSONSerialization.data(withJSONObject: self.values,
            options: JSONSerialization.WritingOptions(rawValue: 0)),
                           encoding: String.Encoding.utf8)!
    }
    
}

/*
open protocol JSONEncodable {
    
    func JSONString() -> String
    
}

func CreateJSONString(obj: AnyObject) -> String {
    return try! String(data: NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0)),
                       encoding: NSUTF8StringEncoding)!
}


*/

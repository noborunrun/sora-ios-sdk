import Foundation

public protocol JSONEncodable {
    
    func JSONString() -> String
    
}

func CreateJSONString(obj: AnyObject) -> String {
    return try! String(data: NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0)),
                       encoding: NSUTF8StringEncoding)!
}

func ParseJSONData(obj: AnyObject) -> AnyObject? {
    var dataOpt: NSData? = nil
    if let s = obj as? String {
        dataOpt = s.dataUsingEncoding(NSUTF8StringEncoding)
    }
    if let data = dataOpt {
        return try? NSJSONSerialization.JSONObjectWithData(data, options:  [])
    } else {
        return nil
    }
}

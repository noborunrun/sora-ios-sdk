import Foundation
import UIKit
import WebP

enum SnapshotError: Error {
    
    case invalidBase64Format
    case WebPDecodeFailed
    case dataProviderInitFailed
    case bitmapImageCreateFailed
    case drawnImageCreateFailed
    
}

public class Snapshot {
    
    public var data: Data!
    public var bitmapImage: CGImage!
    public var drawnImage: UIImage!
    
    init(base64Encoded: String) throws {
        guard let data = Data(base64Encoded: base64Encoded) else {
            throw SnapshotError.invalidBase64Format
        }
        let image = try Snapshot.decode(data: data)
        self.bitmapImage = image.0
        self.drawnImage = image.1
    }
    
    init(data: Data) throws {
        let image = try Snapshot.decode(data: data)
        self.bitmapImage = image.0
        self.drawnImage = image.1
    }
    
    static func decode(data: Data) throws -> (CGImage, UIImage) {
        let len = data.count
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        data.copyBytes(to: buf, count: len)

        let widthBuf = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let heightBuf = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let decodedOpt = WebPDecodeARGB(buf, len, widthBuf, heightBuf)
        let width = Int(widthBuf.pointee)
        let height = Int(heightBuf.pointee)
        
        buf.deallocate(capacity: len)
        widthBuf.deallocate(capacity: 1)
        heightBuf.deallocate(capacity: 1)
        guard let decoded = decodedOpt else {
            throw SnapshotError.WebPDecodeFailed
        }
        
        let providerOpt = CGDataProvider(dataInfo: nil,
                                         data: decoded,
                                         size: width * height * 4) {
                                            _, _, _ in return
        }
        guard let provider = providerOpt else {
            throw SnapshotError.dataProviderInitFailed
        }
        
        let bitmapImageOpt =
            CGImage(width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Little,
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: CGColorRenderingIntent.defaultIntent)
        guard let bitmapImage = bitmapImageOpt else {
            throw SnapshotError.bitmapImageCreateFailed
        }
        
        let image = UIImage(cgImage: bitmapImage)
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            throw SnapshotError.drawnImageCreateFailed
        }
        context.translateBy(x: image.size.width/2, y: image.size.height/2)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let radian = 270 * CGFloat.pi / 180
        context.rotate(by: radian)
        context.draw(bitmapImage, in:
            CGRect(x: -image.size.width/2,
                   y: -image.size.height/2,
                   width: image.size.width,
                   height: image.size.height))
        
        guard let rotated = UIGraphicsGetImageFromCurrentImageContext() else {
            throw SnapshotError.drawnImageCreateFailed
        }
        UIGraphicsEndImageContext()
        
        return (bitmapImage, rotated)
    }
    
}

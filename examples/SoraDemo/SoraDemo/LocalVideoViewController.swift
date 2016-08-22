import Foundation
import AVFoundation
import UIKit
import Sora

class LocalVideoViewController : UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var switchRemoteVideoButton: UIButton!
    
    var connection: Sora.Connection!
    weak var remoteVideoViewController: RemoteVideoViewController!
    var cameraInput: AVCaptureDeviceInput!
    var cameraOutput: AVCaptureVideoDataOutput!
    var cameraSession: AVCaptureSession!
    var cameraPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.Front
    var camera: AVCaptureDevice!

    override func viewWillAppear(animated: Bool) {
        setUpCamera()
    }
    
    func setUpCamera() {
        cameraSession = AVCaptureSession()
        cameraSession.sessionPreset = AVCaptureSessionPresetHigh
        setUpCameraPosition(cameraPosition)
    }
    
    func setUpCameraPosition(pos: AVCaptureDevicePosition) {
        cameraPosition = pos
        for device in AVCaptureDevice.devices() {
            if device.position == pos {
                camera = device as! AVCaptureDevice
            }
        }
        
        do {
            cameraInput = try AVCaptureDeviceInput(device: camera) as AVCaptureDeviceInput
        } catch let error as NSError {
            print(error)
        }
        
        if cameraSession.canAddInput(cameraInput) {
            cameraSession.addInput(cameraInput)
        }
        
        cameraOutput = AVCaptureVideoDataOutput()
        if cameraSession.canAddOutput(cameraOutput) {
            cameraSession.addOutput(cameraOutput)
        }
        
        cameraSession.startRunning()
    }
    
    @IBAction func switchToRemoteVideoView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func switchCameraPosition(sender: AnyObject) {
        switch cameraPosition {
        case AVCaptureDevicePosition.Front:
            setUpCameraPosition(AVCaptureDevicePosition.Back)
        case AVCaptureDevicePosition.Back:
            setUpCameraPosition(AVCaptureDevicePosition.Front)
        default:
            // do nothing
            break
        }
    }
    
}
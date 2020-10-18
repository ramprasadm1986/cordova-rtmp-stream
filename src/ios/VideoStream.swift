import AVFoundation
import HaishinKit
import UIKit
import VideoToolbox

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

@objc(VideoStream) class VideoStream : CDVPlugin {
    
    var rtmpConnection: RTMPConnection? = nil
    var rtmpStream: RTMPStream? = nil
    var hkView : HKView? = nil
    var closeButton: UIButton? = nil
    var streamName: String = ""
    var command:CDVInvokedUrlCommand? = nil
    var maskview : UIView? = nil
  
  @objc(echo:)
  func echo(_ command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let msg = command.arguments[0] as? String ?? ""

    if msg.count > 0 {
      /* UIAlertController is iOS 8 or newer only. */
      let toastController: UIAlertController = 
        UIAlertController(
          title: "", 
          message: msg, 
          preferredStyle: .alert
        )

      self.viewController?.present(
        toastController, 
        animated: true, 
        completion: nil
      )

        let mainQueue = DispatchQueue.main
        let deadline = DispatchTime.now() + .seconds(10)
        mainQueue.asyncAfter(deadline: deadline) {
            toastController.dismiss(
                animated: true,
                completion: nil
            )
        }

      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: msg
      )
    }

    self.commandDelegate!.send(
      pluginResult, 
      callbackId: command.callbackId
    )
  }

  @objc(streamRTMP:)
func streamRTMP(_ command: CDVInvokedUrlCommand) {
    self.command = command
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
            )

        let uri = command.arguments[0] as? String ?? ""
        let streamName = command.arguments[1] as? String ?? ""
   
        self.streamName=streamName
        
        self.rtmpConnection = RTMPConnection()
        self.rtmpStream = RTMPStream(connection: rtmpConnection!)
    
        self.rtmpStream?.captureSettings = [
          .fps: 30, // FPS
          .sessionPreset: AVCaptureSession.Preset.medium, // input video width/height
          .isVideoMirrored: false,
          .continuousAutofocus: false, // use camera autofocus mode
          .continuousExposure: false, //  use camera exposure mode
          .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        self.rtmpStream?.audioSettings = [
          .muted: false, // mute audio
          .bitrate: 32 * 1000,
        ]
       self.rtmpStream?.videoSettings = [
          .width: 845, // video output width
          .height: 480, // video output height
          .bitrate: 2 * 1000, // video output bitrate
          .profileLevel: kVTProfileLevel_H264_Baseline_3_1, // H264 Profile require "import VideoToolbox"
          .maxKeyFrameIntervalDuration: 2, // key frame / sec
        ]
    
    
    
        self.rtmpStream?.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print(error)
        }
       self.rtmpStream?.attachCamera(DeviceUtil.device(withPosition: .front)) { error in
            print(error)
        }
        let view = viewController.view
        self.hkView = HKView(frame: view!.bounds)
        self.hkView?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.hkView?.attachStream(rtmpStream)

    
        view?.addSubview(self.hkView!)
        
       self.closeButton = UIButton(type: .system)
       
       // Position Button
        self.closeButton?.frame = CGRect(x: 10, y: 20, width: 60, height: 40)
   
       // Set text on button
        self.closeButton?.setTitle("Close", for: .normal)
        
        //self.closeButton?.setTitleColor(.red, for: .normal)
        self.closeButton?.backgroundColor = UIColor.darkGray
        self.closeButton?.tintColor = UIColor(rgb: 0x404040)
        
       
       // Set button action
      
    
        self.maskview = UIView(frame: CGRect(x: 0, y: 0, width: (view?.bounds.width)!, height: (view?.bounds.height)!))
      
        self.maskview?.backgroundColor = UIColor(white: 0, alpha: 1)
    
        view?.addSubview(self.maskview!)
       
        view?.addSubview(self.closeButton!)
  
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.rtmpConnection?.connect(uri)
        
        self.closeButton?.addTarget(self, action: #selector(closeAction(_:)), for: .touchUpInside)
        
   
        self.rtmpStream!.publish(self.streamName)
        
       
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: "Streaming to \(uri)"
        )

        self.commandDelegate!.send(
            pluginResult, 
            callbackId: command.callbackId
        )
    }
    
    @objc private func closeAction(_ sender: UIButton?) {
        
        
        self.stopStream()
        
        
    }
    
    @objc private func stopStream(){
        
        rtmpConnection?.close()
        //rtmpStream?.close()
       // rtmpStream?.dispose()
       // rtmpStream?.attachCamera(nil)
        
        closeButton?.removeFromSuperview()
        maskview?.removeFromSuperview()
        hkView?.removeFromSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
    
    @objc private func alerMessage(msg: String){
        
        if msg.count > 0 {
          /* UIAlertController is iOS 8 or newer only. */
          let toastController: UIAlertController =
            UIAlertController(
              title: "",
              message: msg,
              preferredStyle: .alert
            )

          self.viewController?.present(
            toastController,
            animated: true,
            completion: nil
          )

            let mainQueue = DispatchQueue.main
            let deadline = DispatchTime.now() + .seconds(5)
            mainQueue.asyncAfter(deadline: deadline) {
                toastController.dismiss(
                    animated: true,
                    completion: nil
                )
            }

          
        }
        
    }
    
    @objc func rtmpStatusEvent(_ notification: Notification) {
    let e: Event = Event.from(notification)
    if let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String{
            // you can handle errors.
            switch code {
            case RTMPConnection.Code.connectSuccess.rawValue:
                self.alerMessage(msg: "Connected")
                break
            case RTMPConnection.Code.connectRejected.rawValue:
                self.alerMessage(msg: "Unbleto Connect To Server")
                break
            case RTMPConnection.Code.connectClosed.rawValue:
                self.alerMessage(msg: "Disconnected")
                break
            case RTMPConnection.Code.connectFailed.rawValue:
                self.alerMessage(msg: "Unbleto Connect To Server")
                break
            case RTMPConnection.Code.connectIdleTimeOut.rawValue:
                self.alerMessage(msg: "Server Connection Time Out")
                break
            case RTMPStream.Code.publishStart.rawValue:
                self.alerMessage(msg: "Streaming Started")
                break
            case RTMPStream.Code.unpublishSuccess.rawValue:
                break
            default:
                break
            }
        }
    }
}

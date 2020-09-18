import AVFoundation
import HaishinKit
import UIKit

@objc(VideoStream) class VideoStream : CDVPlugin {
  func echo(_ command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let msg = command.arguments[0] as? String ?? ""

    if msg.characters.count > 0 {
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
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
            )

        let uri = command.arguments[0] as? String ?? ""
        let streamName = command.arguments[1] as? String ?? ""
   
        let session = AVAudioSession.sharedInstance()
        do {
            
            if #available(iOS 10.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            } else {
                session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                    AVAudioSession.CategoryOptions.allowBluetooth,
                    AVAudioSession.CategoryOptions.defaultToSpeaker]
                )
                try session.setMode(.default)
            }
            try session.setActive(true)
        } catch {
            print(error)
        }
    
        
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        rtmpStream?.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            print(error)
        }
        rtmpStream?.attachCamera(DeviceUtil.device(withPosition: .back)) { error in
            print(error)
        }
        let view = viewController.view
        hkView = HKView(frame: view!.bounds)
        hkView?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        hkView?.attachStream(rtmpStream)

    
        view?.addSubview(hkView!)
        
       closeButton = UIButton(type: .system)
       
       // Position Button
       closeButton?.frame = CGRect(x: 20, y: 20, width: 100, height: 50)
       closeButton.center = view.center
       // Set text on button
       closeButton?.setTitle("Close", for: .normal)
       closeButton?.setTitle("Close", for: .highlighted)
       
       // Set button action
      
       
        view?.addSubview(closeButton!)
  
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        rtmpConnection?.connect(uri)
        
        closeButton?.addTarget(self, action: #selector(closeAction(_:)), for: .touchUpInside)
        
        
        rtmpStream?.publish(streamName)
        
        
        
        
        
        
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
        
        rtmpConnection?.close()
        rtmpStream?.close()
        rtmpStream?.dispose()
        rtmpStream?.attachCamera(nil)
        
        closeButton?.removeFromSuperview()
        hkView?.removeFromSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

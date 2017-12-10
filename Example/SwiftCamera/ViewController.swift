//
//  ViewController.swift
//  SwiftCamera
//
//  Created by Mohamed Rias on 12/06/2017.
//  Copyright (c) 2017 Mohamed Rias. All rights reserved.
//

import UIKit
import SwiftCamera
import AVFoundation

class ViewController: UIViewController, SwiftCameraDelegate {
    var swiftCamera: SwiftCamera!
    
    @IBOutlet weak var videoPreviewImg: UIImageView!
    @IBOutlet weak var videoPreview: UIView!
    /* Lifecycle
     ------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        swiftCamera = SwiftCameraBuilder().setDelegate(self).disableVideoOutput().build()
        swiftCamera.setupPreviewLayer(self.videoPreview, videoAspect: .AspectFill)
        swiftCamera.startCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        swiftCamera.teardownCamera()
    }
    
    
    /* Instance Methods
     ------------------------------------------*/
    
    //    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    //        if let touch = touches.first {
    //            let position :CGPoint = touch.locationInView(view)
    //            self.swiftCamera.focusAndExposeAtPoint(position)
    //        }
    //    }
    
    
    /* Delegate Methods
     ------------------------------------------*/
    
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if connection.supportsVideoOrientation {
            connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        }
        if connection.supportsVideoMirroring {
            connection.videoMirrored = true
        }
    }
    
    func appDidNotAuthorizeCameraPermission(success: Bool) {
        
    }
    
    
    @IBAction func takePicAction(sender: AnyObject) {
        swiftCamera?.captureImage({ (image, error) in
            if let image = image {
                self.videoPreviewImg?.image = image
            }
        })
    }
    
}




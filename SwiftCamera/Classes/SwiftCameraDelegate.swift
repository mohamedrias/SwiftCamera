//
//  SwiftCameraControllerDelegate.swift
//  SwiftCamera
//
//  Created by Mohamed Rias on 12/06/17.
//  Copyright (c) 2014 Mohamed Rias. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage


@objc public protocol SwiftCameraDelegate {
    
    /**
     In case, user wants to process the buffer and do some image processing, this delegate method will be invoked.
     
     - parameter sampleBuffer: CMSampleBuffer
     - parameter connection:   AVCaptureConnection
     */
    optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    
    
    /**
     Invoked when user has not provided camera permission
     
     - parameter success: Bool
     */
    func appDidNotAuthorizeCameraPermission(success: Bool)
    
}
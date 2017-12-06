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
    optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    func appDidNotAuthorizeCameraPermission(success: Bool)
    
}
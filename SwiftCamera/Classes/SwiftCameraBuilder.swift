//
//  SwiftCameraBuilder.swift
//  SwiftCamera
//
//  Created by Mohamed Rias on 12/06/17.
//  Copyright (c) 2014 Mohamed Rias. All rights reserved.
//
import AVFoundation

public class SwiftCameraBuilder {
    
    private var cameraController: SwiftCamera!
    
    var enableVideo: Bool
    var enableVideoOutput: Bool
    var enableStillImage: Bool
    var cameraPosition: AVCaptureDevicePosition
    var delegate: SwiftCameraDelegate!
    
    public init() {
        self.enableVideo = true
        self.enableVideoOutput = true
        self.enableStillImage = true
        self.cameraPosition = .Back
    }
    
    public func disbaleVideo() -> SwiftCameraBuilder {
        self.enableVideo = false
        return self
    }
    
    public func disableVideoOutput() -> SwiftCameraBuilder {
        self.enableVideoOutput = false
        return self
    }
    
    public func disableStillImage() -> SwiftCameraBuilder {
        self.enableStillImage = false
        return self
    }
    
    public func setDelegate(delegate: SwiftCameraDelegate) -> SwiftCameraBuilder {
        self.delegate = delegate
        return self
    }
    
    public func setCameraPosition(position: AVCaptureDevicePosition) -> SwiftCameraBuilder {
        self.cameraPosition = position
        return self
    }
    
    public func build() -> SwiftCamera {
        self.cameraController = SwiftCamera(builder: self)
        return self.cameraController
    }
    
    
}
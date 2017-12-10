//
//  SwiftCamera.swift
//  SwiftCamera
//
//  Created by Mohamed Rias on 12/06/17.
//  Copyright (c) 2014 Mohamed Rias. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage

public class SwiftCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput!
    var stillImageOutput: AVCaptureStillImageOutput!
    var runtimeErrorHandlingObserver: AnyObject?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var previewView: UIView!
    var cameraPosition: AVCaptureDevicePosition! = .Back
    
    var sessionDelegate: SwiftCameraDelegate?
    
    
    /* Class Methods
     ------------------------------------------*/
    
    class func deviceWithMediaType(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices: NSArray = AVCaptureDevice.devicesWithMediaType(mediaType as String)
        var captureDevice: AVCaptureDevice = devices.firstObject as! AVCaptureDevice
        
        for object:AnyObject in devices {
            let device = object as! AVCaptureDevice
            if (device.position == position) {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    
    /* Lifecycle
     ------------------------------------------*/
    
    private override init() {
        super.init();
        
        self.session = AVCaptureSession()
        
        self.authorizeCamera();
        
        self.sessionQueue = dispatch_queue_create("com.mohamedrias.swiftcamera.queue", DISPATCH_QUEUE_SERIAL)
        
    }
    
    convenience init(builder: SwiftCameraBuilder) {
        self.init()
        self.configure(builder)
    }
    
    
    /* Instance Methods - Public
     ------------------------------------------*/
    
    /**
     Configure the SwiftCamera instance with the appropriate properties
     
     - parameter builder: SwiftCameraBuilder instance with the config attributes
     
     - returns: SwiftCamera instance
     */
    public func configure(builder: SwiftCameraBuilder) -> SwiftCamera {
        dispatch_async(self.sessionQueue, {
            self.session.beginConfiguration()
            self.cameraPosition = builder.cameraPosition
            if builder.enableVideo {
                self.addVideoInput()
            }
            if builder.enableVideoOutput {
                self.addVideoOutput()
            }
            if builder.enableStillImage {
                self.addStillImageOutput()
            }
            self.session.commitConfiguration()
        })
        return self
    }
    
    
    /**
     Specifies the previewLayer for the camera view. Any custom camera preview view should be passed to this instance
     
     - parameter videoPreview: UIView used for previewing the camera source
     - parameter videoAspect:  Aspect ratio of the camera
     
     - returns: AVCaptureVideoPreviewLayer
     */
    public func setupPreviewLayer(videoPreview: UIView, videoAspect: VideoAspect) -> AVCaptureVideoPreviewLayer {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewView = videoPreview
        self.previewLayer.bounds = self.previewView.bounds
        videoPreview.clipsToBounds = true
        self.previewLayer.position = CGPointMake(CGRectGetMidX(self.previewView.bounds), CGRectGetMidY(self.previewView.bounds))
        self.previewLayer.videoGravity = videoAspect.gravity()
        self.previewView.layer.addSublayer(self.previewLayer)
        return self.previewLayer
        
    }
    
    
    /**
     Specifies whether camera permission is given to the user or not
     
     - parameter completion: Completion handler with the boolean attribute passed to it 
     which specifies whether permission is granted or not/.
     */
    public func isCameraAuthorized(completion:(granted: Bool) -> Void) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            completion(granted: granted)
        })
    }
    
    
    /**
     Useful to request permission from the user. If delegate is set, the delegate will be invoked. 
     Handle the permission message as required.
     
     If no delegate is set, default alert will be shown.
     */
    public func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                if let delegate = self.sessionDelegate {
                    delegate.appDidNotAuthorizeCameraPermission(granted)
                    return
                }
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                })
            }
        });
    }
    
    /**
     Start camera method to instantiate the camera view
     */
    public func startCamera() {
        dispatch_async(self.sessionQueue, {
            let weakSelf: SwiftCamera? = self
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.sessionQueue, queue: nil, usingBlock: {
                (note: NSNotification) -> Void in
                
                let strongSelf: SwiftCamera = weakSelf!
                
                dispatch_async(strongSelf.sessionQueue, {
                    strongSelf.session.startRunning()
                })
            })
            self.session.startRunning()
        })
    }
    
    /**
     Stop the camera view and deallocate memory consumed
     */
    public func teardownCamera() {
        dispatch_async(self.sessionQueue, {
            self.session.stopRunning()
            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver!)
        })
    }
    
    
    /**
     Add touch gesture to the view to manually focus the camera
     
     - parameter point: CGPoint
     */
    public func focusAndExposeAtPoint(point: CGPoint) {
        dispatch_async(self.sessionQueue, {
            let device: AVCaptureDevice = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                if device.focusPointOfInterestSupported && device.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = AVCaptureFocusMode.AutoFocus
                }
                
                if device.exposurePointOfInterestSupported && device.isExposureModeSupported(AVCaptureExposureMode.AutoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = AVCaptureExposureMode.AutoExpose
                }
                
                device.unlockForConfiguration()
            } catch _ {
                /* TODO: Finish migration: handle the expression passed to error arg: error */
                // TODO: Log error.
            }
        })
    }
    
    
    /**
     Captures the image from the preview layer
     
     - parameter completion: (image: UIImage?, error: NSError?)
     */
    public func captureImage(completion:((image: UIImage?, error: NSError?) -> Void)?) {
        if completion == nil || self.stillImageOutput == nil{
            return
        }
        self.isCameraAuthorized { (granted) in
            if granted {
                dispatch_async(self.sessionQueue, {
                    self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo), completionHandler: {
                        (imageDataSampleBuffer: CMSampleBuffer?, error: NSError?) -> Void in
                        if imageDataSampleBuffer == nil || error != nil {
                            completion?(image:nil, error:nil)
                            return
                        }
                        else if imageDataSampleBuffer != nil {
                            let imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                            if let image: UIImage = UIImage(data: imageData) {
                                if let croppedImage = self.captureStillImageFromPreviewLayer(image) {
                                    completion!(image:croppedImage, error:nil)
                                    return
                                }
                                completion?(image:image, error:nil)
                                return
                            }
                        }
                        completion?(image:nil, error:nil)
                    })
                })       
            }
        }
    }
    
    
    
    /* Instance Methods - Private
     ------------------------------------------*/
    
    /**
     Setup camera input device (back facing camera) and add input feed to our AVCaptureSession session.
     
     - returns: Boolean
     */
    func addVideoInput() -> Bool {
        var success: Bool = false
        let videoDevice: AVCaptureDevice = SwiftCamera.deviceWithMediaType(AVMediaTypeVideo, position: self.cameraPosition)
        do  {
            self.videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice) as AVCaptureDeviceInput;
            //### When error occures, the rest of the code in do-catch will not be executed, you have no need to check `error`.
            if self.session.canAddInput(self.videoDeviceInput) {
                self.session.addInput(self.videoDeviceInput)
                success = true
            }
        } catch let error as NSError {
            // Handle all errors
            print(error)
            //...
        }
        
        return success
    }
    
    /**
     Setup capture output for our video device input.
     */
    func addVideoOutput() {
        
        self.videoDeviceOutput = AVCaptureVideoDataOutput()
        self.videoDeviceOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        self.videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        
        self.videoDeviceOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        
        if self.session.canAddOutput(self.videoDeviceOutput) {
            self.session.addOutput(self.videoDeviceOutput)
        }
    }
    
    /**
     Whether to have capability to capture still image from the camera source
     */
    func addStillImageOutput() {
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if self.session.canAddOutput(self.stillImageOutput) {
            self.session.addOutput(self.stillImageOutput)
        }
    }
    
    
    /**
     Captures still image from the preview layer and also crops it to the dimension of the preview.
     
     - parameter image: UIImage
     
     - returns: Cropped image as per the preview layer
     */
    func captureStillImageFromPreviewLayer(image: UIImage) -> UIImage? {
        let originalSize : CGSize
        // The actual visible layer in the camera frame
        let visibleLayerFrame = self.previewView.bounds
        let metaRect : CGRect = (self.previewLayer?.metadataOutputRectOfInterestForRect(visibleLayerFrame))!
        if (image.imageOrientation == UIImageOrientation.Left || image.imageOrientation == UIImageOrientation.Right) {
            // For these images (which are portrait), swap the size of the
            // image, because here the output image is actually rotated
            // relative to what you see on screen.
            originalSize = CGSize(width: image.size.height, height: image.size.width)
        }
        else {
            originalSize = image.size
        }
        
        // metaRect is fractional, that's why we multiply here.
        let cropRect : CGRect = CGRectIntegral(
            CGRect( x: metaRect.origin.x * originalSize.width,
                y: metaRect.origin.y * originalSize.height,
                width: metaRect.size.width * originalSize.width,
                height: metaRect.size.height * originalSize.height))
        
        let finalImage =
            UIImage(CGImage: CGImageCreateWithImageInRect(image.CGImage, cropRect)!,
                    scale:1,
                    orientation: image.imageOrientation )
        return finalImage
    }
    
    
    /* AVCaptureVideoDataOutputSampleBufferDelegate Delegate Methods
     ------------------------------------------*/
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        self.sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer, fromConnection:connection)
    }
    
    
    /**
     Enum to define the camera aspect
     
     - AspectFill:  Fills the screen with aspect
     - AspectFit:   Fits the screen as per the aspect
     - ScaleToFill: Fills the screen without aspect
     */
    public enum VideoAspect {
        case AspectFill, AspectFit, ScaleToFill
        
        func gravity() -> String {
            switch self {
            case .AspectFit:
                return AVLayerVideoGravityResizeAspect
            case .AspectFill:
                return AVLayerVideoGravityResizeAspectFill
            case .ScaleToFill:
                return AVLayerVideoGravityResize
            }
        }
    }
    
}
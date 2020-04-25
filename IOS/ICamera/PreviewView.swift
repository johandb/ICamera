//
//  PreviewView.swift
//  ICamera
//
//  Created by Johan den Boer on 03/04/2020.
//  Copyright © 2020 Johan den Boer. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

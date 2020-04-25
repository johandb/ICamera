import UIKit

import AVFoundation
import Socket

class ViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var assetWriter: AVAssetWriter?
    private var videoWriterOutput: AVAssetWriterInput?
    private var audioWriterOutput: AVAssetWriterInput?
    private var _adpater: AVAssetWriterInputPixelBufferAdaptor?
    
    private var isRecording = false
    private var isConnected = false
    
    private var saved = false
    
	// Change this to your own ip address
    let host = "192.168.1.10"
	// Change this to the port number you want
    let port: Int32 = 9000
    var socket: Socket?

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    override func viewDidLoad() {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCaptureSession()
        @unknown default:
            break
        }
        self.setupConnection()
    }
    
    private func setupConnection() {
        socket = try? Socket.create(family: .inet)
        try? socket!.connect(to: host, port: port, timeout: 2000, familyOnly: true)
    }
    
    private func setupCaptureSession() {
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = .vga640x480

        self.captureSession!.beginConfiguration()
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
            if self.captureSession!.canAddInput(videoInput!) {
                self.captureSession!.addInput(videoInput!)
            }
        }
        if let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio) {
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
            if self.captureSession!.canAddInput(audioInput!) {
                self.captureSession!.addInput(audioInput!)
            }
        }

        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput?.alwaysDiscardsLateVideoFrames = false
        guard self.captureSession!.canAddOutput(self.videoOutput!) else { return }
        
        self.audioOutput = AVCaptureAudioDataOutput()
        guard self.captureSession!.canAddOutput(self.audioOutput!) else { return }
        
        self.videoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.example.icamera"))
        self.audioOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.example.icamera"))
        
        self.captureSession!.addOutput(self.videoOutput!)
        self.captureSession!.addOutput(self.audioOutput!)

        self.captureSession!.commitConfiguration()

        DispatchQueue.main.async {
            let previewView = PreviewView()
            previewView.videoPreviewLayer.session = self.captureSession!
            previewView.frame = self.view.bounds
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.insertSubview(previewView, at: 0)
        }

        self.captureSession!.startRunning()
    }
    
    private func setupWriter() {
        let fileName = UUID().uuidString
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let outputURL = URL(fileURLWithPath: documentsPath!).appendingPathComponent("\(fileName).mov")
        self.assetWriter = try! AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        // Video
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 640,
            AVVideoHeightKey: 480,
        ]
        self.videoWriterOutput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings as [String : Any])
        self.videoWriterOutput!.mediaTimeScale = CMTimeScale(bitPattern: 600)
        self.videoWriterOutput!.expectsMediaDataInRealTime = true
        self.videoWriterOutput!.transform = CGAffineTransform(rotationAngle: .pi/2)
        if self.assetWriter!.canAdd(self.videoWriterOutput!) {
            self.assetWriter!.add(self.videoWriterOutput!)
        }

        // Audio
        let audioSettings: [String: Any]  = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
        ]
        self.audioWriterOutput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
        self.audioWriterOutput?.expectsMediaDataInRealTime = true
        if self.assetWriter!.canAdd(self.audioWriterOutput!) {
            self.assetWriter!.add(self.audioWriterOutput!)
        }
        
        let presentationStartTime = CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 240)
        self.assetWriter?.startWriting()
        self.assetWriter?.startSession(atSourceTime: presentationStartTime)
    }
    
    private func stopWriting() {
    }

    @IBAction func cameraButtonAction(_ sender: UIButton) {
        self.captureSession?.beginConfiguration()
        if let currentCameraInput = self.captureSession?.inputs.first as? AVCaptureDeviceInput {
            self.captureSession?.removeInput(currentCameraInput)
            var cameraPosition = currentCameraInput.device.position
            switch cameraPosition {
            case .unspecified, .front:
                cameraPosition = .back
            case .back:
                cameraPosition = .front
            @unknown default:
                print("Unknown capture position. Defaulting to back.")
                cameraPosition = .back
            }
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) {
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession!.canAddInput(videoInput!) {
                    self.captureSession?.addInput(videoInput!)
                }
            }
        }
        self.captureSession?.commitConfiguration()
    }
    
    @IBAction func playButtonAction(_ sender: Any) {
        if !isRecording {
            if let image = UIImage(named: "stop") {
                self.playButton.setImage(image, for: .normal)
            }
            self.setupWriter()
        } else {
            if let image = UIImage(named: "record") {
                self.playButton.setImage(image, for: .normal)
            }
            self.videoWriterOutput?.markAsFinished()
            assetWriter?.finishWriting { [weak self] in
                self?.stopWriting()
                // If you want to save the video uncomment next two line
                // let url = self.assetWriter?.outputURL
                // UISaveVideoAtPathToSavedPhotosAlbum(url!.path, nil, nil, nil)
            }
        }
        isRecording = !isRecording
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isRecording {
            if output == self.videoOutput {
                if videoWriterOutput?.isReadyForMoreMediaData == true {
                    let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                    let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
                    let newImage = self.convert(cmage: ciimage)
                    let data = newImage.pngData()
                    /*
                     * Every packet has the format :
                     * 1 - 8 digits - png image size
                     * 9 - ? bytes of png data
                     */
                    let packet = RTPacket(size: String(format: "@%08d", data!.count), data: data!)
                    _ = try? self.socket!.write(from: packet.serialize())
                    self.videoWriterOutput?.append(sampleBuffer)
                }
            }
            if output == audioOutput {
                if audioWriterOutput?.isReadyForMoreMediaData == true {
                    self.audioWriterOutput?.append(sampleBuffer)
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage
    {
         let context:CIContext = CIContext.init(options: nil)
         let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
         let image:UIImage = UIImage.init(cgImage: cgImage)
         return image
    }
}


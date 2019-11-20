//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Всеволод Андрющенко on 20.11.2019.
//  Copyright © 2019 Всеволод Андрющенко. All rights reserved.
//

import UIKit
import AVFoundation
import Vision


class ViewController: UIViewController {
    
    
    //@IBOutlet weak var camView: UIImageView!
    @IBOutlet weak var camView: UIView!
    @IBOutlet weak var outputString: UILabel!
    @IBOutlet weak var stateButton: UIButton!
    
    var isStart: Bool = false
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var stilImageOutput: AVCaptureVideoDataOutput?
    var i: Int = 0
    
    
    //MARK: - Init sessionQueu
    let sessionQueue = DispatchQueue(label: "CamWorck", qos: .userInitiated)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentCamera()
        outputString.text = ""
    }
    
    //MARK: - получение изображения с камеры
    fileprivate func presentCamera(){
        sessionQueue.async {
            let backCam = AVCaptureDevice.default(for: AVMediaType.video)
            
            var input: AVCaptureDeviceInput?
            var error: NSError?
            
            do {
                guard let cam = backCam else { return }
                input = try AVCaptureDeviceInput(device: cam)
            } catch let errorLocal as NSError {
                
                error = errorLocal
                input = nil
                self.alertPresent(errorLocal)
            }
            guard let inputVarp = input else { return }
            
            if error == nil && self.session.canAddInput(inputVarp){
                self.session.addInput(inputVarp)
                self.stilImageOutput = AVCaptureVideoDataOutput()
                guard let dataOutput = self.stilImageOutput else { return }
                if self.session.canAddOutput(dataOutput){
                    self.session.addOutput(dataOutput)
                    dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video"))
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                    self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    if let preview = self.previewLayer{
                        DispatchQueue.main.async {
                            preview.frame = self.camView.bounds
                            self.camView.layer.addSublayer(preview)
                            self.session.startRunning()
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func alertPresent(_ error: Error) {
        let alert = UIAlertController(title: "ERROR!", message: error.localizedDescription , preferredStyle: .alert)
        let actionAlert = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(actionAlert)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buttonPress(_ sender: Any) {
        isStart = !isStart
        if isStart {
            stateButton.backgroundColor = .systemRed
            stateButton.setTitle("Stop", for: .normal)
        } else {
            stateButton.backgroundColor = .systemGreen
            stateButton.setTitle("Start", for: .normal)
            outputString.text = ""
            i = 0
        }
        
    }
}
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    //MARK: - обработка кадров из камеры
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if isStart{
            i += 1
            
            if i % 15 == 0{
                guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                guard let model = try? VNCoreMLModel(for: MobileNet().model) else { return }
                
                let reqest = VNCoreMLRequest(model: model) { (reqest, err) in
                    if let error = err{
                        self.alertPresent(error)
                    } else {
                        guard let result = reqest.results as? [VNClassificationObservation] else { return }
                        
                        guard let firstObjet =  result.first else { return }
                        
                        DispatchQueue.main.async {
                            if firstObjet.confidence < 0.7{
                                self.outputString.text = firstObjet.identifier
                            } else {
                                self.outputString.text = "object not detected"
                            }
                        }
                    }
                }
                try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([reqest])
            }
        }
    }
}


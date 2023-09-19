//
//  ViewController.swift
//  WhatText
//
//  Created by Gürcan Kırık on 5.04.2023.
//

import UIKit
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    
    
    let imagePicker = UIImagePickerController()
    
    //Create an instance of VNRequest's subclass. Here VNRecognizeTextRequest is used.
    
    var ocrRequest = VNRecognizeTextRequest()
//    var ocrRequest2 = VNRecognizeTextRequestRevision1
    
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
//        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        configureOCR()
        
        
//        print(try! ocrRequest.supportedRecognitionLanguages())
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            imageView.image = userPickedImage
            let cgFormattedImage = userPickedImage.cgImage
            
            let requestHandler = VNImageRequestHandler(cgImage: cgFormattedImage!, orientation: .up, options: [:])
            
            do {
                try requestHandler.perform([self.ocrRequest])
                
            } catch {
                print(error)
            }
            
            
        }
        imagePicker.dismiss(animated: true)
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action: UIAlertAction) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action: UIAlertAction) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(actionSheet, animated: true)
    }
    
    
    func configureOCR() {
        ocrRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var ocrText = ""
            
            var rects : [CGRect] = []
            var boxes : [CGRect] = []
            let cgimage = self.imageView!.image!.cgImage
            let image = self.imageView!.image!
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                    let rect = observation.boundingBox //Bounding box returned from Vision framework. It şs normalized and flipped in y-axis.s
                boxes.append(rect)
                    let size = CGSize(width: cgimage!.width, height: cgimage!.height) // Image size in pixels.
                    let imgSizedRect = CGRect(origin: .zero, size: size) //Create a CGRect in size with the image. This will be used to project detected box onto image.

                    let boxToDraw = self.getOriginalBoundingBox(boundingBox: rect, originalImgSizedRect: imgSizedRect)
                rects.append(boxToDraw)
//                    self.drawRectangleOnImage(self.imageView.image!, rectangle: rect)

                ocrText += topCandidate.string + "\n"
            }
            
            let finalImg = self.drawRectangleOnImage(image, rectangle: rects)
            
            
            
            
            DispatchQueue.main.async {
                self.imageView.image = finalImg
//                self.imageView.contentMode = .bottomLeft
                self.textView.text = ocrText
                
            }
        }
        
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["en-US", "en-GB"]
        ocrRequest.usesLanguageCorrection = true
        
        
        
    }
    
    
    
    func getOriginalBoundingBox (boundingBox: CGRect, originalImgSizedRect: CGRect) -> CGRect{
        var rectOut = boundingBox
        rectOut.origin.x = rectOut.origin.x * originalImgSizedRect.width
        rectOut.origin.x += originalImgSizedRect.minX
        rectOut.origin.y = (1-rectOut.maxY) * originalImgSizedRect.height + originalImgSizedRect.minY
        rectOut.size.height *= originalImgSizedRect.height
        rectOut.size.width *= originalImgSizedRect.width
        return rectOut
    }
    
    
    func drawRectangleOnImage(_ image: UIImage, rectangle: [CGRect])->UIImage{
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
//        image.draw(at: CGPoint.zero)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        guard let context = UIGraphicsGetCurrentContext()else{return image}
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2)
        for cgrect in rectangle{
            
            context.stroke(cgrect)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
}



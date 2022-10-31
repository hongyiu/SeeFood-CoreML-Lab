//
//  ViewController.swift
//  SeeFood
//
//  Created by Hong Yiu Yu on 28/10/2022.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[.editedImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            
            detect(image: convertedCIImage)
            
        }
        
        imagePicker.dismiss(animated: true)
        
    }
    
    func detect(image: CIImage) {
        
//        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
//            fatalError("Loading CoreML Model Failed.")
//        }
        
        guard let model = try? VNCoreMLModel(for: MyImageClassifier_1().model) else {
            fatalError("Loading CoreML Model Failed.")
        }

        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("model failed to process image.")
            }
            

            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(name: firstResult.identifier)
//                print("Detect: \(firstResult.identifier)")
//                if firstResult.identifier.contains("hotdog") {
//                    self.navigationItem.title = "Hotdog!"
//                } else {
//                    self.navigationItem.title = "Not Hotdog!"
//                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(name: String) {
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts",
          "exintro" : "",
          "explaintext" : "",
          "titles" : name,
          "indexpageids" : "",
          "redirects" : "1",
          ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the Wikipedia info")
                print(response)
                
                let resultJSON : JSON = JSON(response.result.value!)
                
                let pageid = resultJSON["query"]["pageids"][0].stringValue
                
                let resultDescription = resultJSON["query"]["pages"][pageid]["extract"].stringValue
                
                self.label.text = resultDescription.isEmpty ? "Cannot find the description of \(name.capitalized)" : resultDescription
                
            }
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true)
    }
    
}


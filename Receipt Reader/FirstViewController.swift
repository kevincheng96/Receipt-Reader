//
//  FirstViewController.swift
//  Receipt Reader
//
//  Created by Kevin Cheng on 12/23/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

// THINGS TO DO:
// Implement Core Data to save user receipts (do later)
// Make sure photo cropping works
// Be able to parse receipts for numbers in order to correctly save entries (WORK ON THIS NOW)
// Work on improving tesseract OCR readings (black and white, size, filtering, etc.)
// Also allow users to self-input purhcases
// Design a "How to use" tab
// Have a rescan button

import UIKit

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var receiptTextView: UITextView!
    
    var activityIndicator:UIActivityIndicatorView!
    var recognizedText:String!
    var arrayOfItems:[String]?
    var itemPriceDict:[String:Double]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // creates an Action Sheet allowing the user to choose a photo from library or take a photo
    @IBAction func pickPhoto(sender: AnyObject) {
        
        let imagePickerActionSheet = UIAlertController(title: "Take/Choose a photo", message: nil, preferredStyle: .ActionSheet)
        
        // take a photo of receipt from camera
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo", style: .Default, handler: { (alert) -> Void in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = true // CHECK TO SEE IF IT ACTUALLY ALLOWS EDITING
                imagePicker.sourceType = .Camera
                self.presentViewController(imagePicker, animated: true, completion: nil)
            })
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        // choose photo from photo library
        let libraryButton = UIAlertAction(title: "Choose Existing", style: .Default) { (alert) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)

        // cancel button
        let cancelButton = UIAlertAction(title: "Cancel", style: .Default) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        
        presentViewController(imagePickerActionSheet, animated: true,
            completion: nil)
    }
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }
    
    // Scale image size for better tesseract readings
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func performImageRecognition(image: UIImage) {
        let tesseract:G8Tesseract = G8Tesseract(language:"eng")
        tesseract.engineMode = .TesseractCubeCombined
        tesseract.pageSegmentationMode = .Auto
        tesseract.maximumRecognitionTime = 60.0
        /* deprecated function (need to change) https://github.com/gali8/Tesseract-OCR-iOS/wiki/Tips-for-Improving-OCR-Results */
        tesseract.image = image.g8_blackAndWhite()
        tesseract.recognize()
        
        recognizedText = tesseract.recognizedText
        
        removeActivityIndicator()
    }
    
    // Parses and seperates string into its elements (item - price pair)
    func parseText(text: String) {
        // Everytime there is a number followed by a line break, seperate it and store it into the array
        // So each element in array has a string followed by a price number
        var arr = text.componentsSeparatedByCharactersInSet(.newlineCharacterSet())
        arrayOfItems = arr.filter({$0 != "" && $0 != " "})
        var receiptText = join("\n", arrayOfItems!)
        receiptTextView.text = receiptText
        NSLog("%@", arr)
        
        // Then seperate the string and price and store them into a dictionary of item:prices
        // itemPriceDict
    }
}

extension FirstViewController: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        let selectedPhoto = info[UIImagePickerControllerEditedImage] as UIImage // change to edited image???
        let scaledImage = scaleImage(selectedPhoto, maxDimension: 640)
        
        addActivityIndicator()
        
        dismissViewControllerAnimated(true, completion: {
            self.imageView.image = selectedPhoto
            self.performImageRecognition(scaledImage)
            self.parseText(self.recognizedText)
        })
    }
}


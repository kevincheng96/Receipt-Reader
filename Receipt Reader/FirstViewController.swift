//
//  FirstViewController.swift
//  Receipt Reader
//
//  Created by Kevin Cheng on 12/23/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

// THINGS TO DO:
// Implement Core Data to save user receipts (do later) OR use Parse.io
// Have custom photo cropping (maybe using an open source library)
// Work on improving tesseract OCR readings (black and white, size, filtering, etc.)
// Also allow users to self-input purchases
// Design a "How to use" tab
// Find a way to track the number of the same items bought (if item exists in dictionary, increment count by 1?)
// Still need to filter out $ sign from prices
// Low priority: implement a smart system that edits similar text to match items already in dictionary
// Need to work on UI/UX (Need clear instructions at the top to explain the user has to seperate lines)
// Store Receipt button must be hidden and then show after taking a picture
// Have a rescan button
// Grab date and save receipts under dates

import UIKit

class FirstViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var receiptTextView: UITextView!
    
    var activityIndicator:UIActivityIndicatorView!
    var recognizedText:String!
    var arrayOfItems:[String]?
    var itemPriceDict:[String:Double] = [:]
    
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
        
        /* var arr = text.componentsSeparatedByCharactersInSet(.newlineCharacterSet()) */
        var arr:[String] = []
        text.enumerateLines { (line, stop) -> () in
            arr.append(line)
        }
        arrayOfItems = arr.filter({$0 != "" && $0 != " "})
        let receiptText = (arrayOfItems!).joinWithSeparator("\n")
        receiptTextView.text = receiptText // UPDATING VIEW SHOULD BE OUTSIDE OF THIS FUNCTION
        
        // Then seperate the string and price and store them into a dictionary of item:prices
        // itemPriceDict
        
    }
    
    // Ask user to enter a line break after each price
    // After user seperates each line of receipt with a line break, stores the data into the database
    @IBAction func storeReceipt(sender: AnyObject) {
        let receiptText = receiptTextView.text
        var arr:[String] = []
        receiptText.enumerateLines { (line, stop) -> () in //seperate the user editted text into lines again
            arr.append(line)
        }
        arrayOfItems = arr.filter({$0 != "" && $0 != " "})
        
        for line in arrayOfItems! { //read each line to extract the item and price
            var lineArr = line.componentsSeparatedByString(" ") //split the line into an array of words
            // var lineArr = split(line) {$0 == " "}
            if !lineArr.isEmpty {
                let price = lineArr.last //price should be the last word in the array
                // still need to filter out the dollar signs if there are in price
                let pricedouble = (price! as NSString).doubleValue
                let lastindex = lineArr.count - 1
                lineArr.removeAtIndex(lastindex)
                let item = lineArr.joinWithSeparator(" ")
                
                itemPriceDict[item] = pricedouble //add item and price to dictionary!
            }
        }
        for (item, price) in itemPriceDict {
            NSLog("Item: \(item) \n Price: \(price)")
        }
    }
}

extension FirstViewController: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let selectedPhoto = info[UIImagePickerControllerEditedImage] as! UIImage // change to edited image???
        let scaledImage = scaleImage(selectedPhoto, maxDimension: 640)
        
        addActivityIndicator()
        
        dismissViewControllerAnimated(true, completion: {
            self.imageView.image = selectedPhoto
            self.performImageRecognition(scaledImage)
            self.parseText(self.recognizedText)
        })
    }
}
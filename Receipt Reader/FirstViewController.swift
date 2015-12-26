//
//  FirstViewController.swift
//  Receipt Reader
//
//  Created by Kevin Cheng on 12/23/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.image = UIImage(named: "example.png");
        tesseract.recognize();
        
        NSLog("%@", tesseract.recognizedText);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


//
//  LicenseDetailController.swift
//  Spotty
//
//  Created by Cameron Eubank on 10/13/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit

class LicenseDetailController: UIViewController {

    @IBOutlet var licenseWebView: UIWebView!
    var licenseString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        title = licenseString
        
        //Load html in webview
        licenseWebView.loadRequest(URLRequest(url: URL(fileURLWithPath: Bundle.main.path(forResource: licenseString, ofType: "html")!)))


    }


}

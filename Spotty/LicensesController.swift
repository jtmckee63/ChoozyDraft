//
//  LicensesController.swift
//  Spotty
//
//  Created by Cameron Eubank on 10/13/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit

class LicensesController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var licensesTableView: UITableView!
    
    var licenses: [String] = ["Alamofire", "AlamofireImage", "JRMFloatingAnimation", "SideMenu"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        view.backgroundColor = UIColor.purple.dark
        
        title = "Licenses"
        
        licensesTableView.delegate = self
        licensesTableView.dataSource = self
        licensesTableView.backgroundColor = UIColor.purple.light

    }
    
    //MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style:UITableViewCellStyle.subtitle, reuseIdentifier: "cell")
        let license = licenses[indexPath.row]
        cell.textLabel?.text = license
        cell.textLabel?.textColor = UIColor.white.flat
        cell.textLabel?.font = UIFont(name: "Jellee-Roman", size: 12.0)
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return licenses.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let license = licenses[indexPath.row]
        self.showLicenseDetailController(license)
        
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "license"{
            let licenseDetailController: LicenseDetailController = segue.destination as! LicenseDetailController
            licenseDetailController.licenseString = (sender as? String)!
        }
    }
}

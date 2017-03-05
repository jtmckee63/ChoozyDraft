//
//  AboutController.swift
//  Spotty
//
//  Created by Cameron Eubank on 10/13/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit

class AboutController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var aboutScrollView: UIScrollView!
    @IBOutlet var aboutContentView: UIView!
    @IBOutlet var aboutImageView: UIImageView!
    @IBOutlet var aboutTableView: UITableView!
    
    var aboutItems: [String] = ["Share Choozy", "Give us Feedback", "Licenses"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        title = "About"
        
        //About Content View
        aboutContentView.backgroundColor = UIColor.purple.dark
        
        //About TableView
        aboutTableView.delegate = self
        aboutTableView.dataSource = self
        aboutTableView.backgroundColor = UIColor.purple.light

    }
    
    //MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style:UITableViewCellStyle.subtitle, reuseIdentifier: "cell")
        let item = aboutItems[indexPath.row]
        cell.textLabel?.text = item
        cell.textLabel?.font = UIFont(name: "Jellee-Roman", size: 12.0)
        cell.textLabel?.textColor = UIColor.white.flat
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aboutItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let item = aboutItems[row]
        
        switch row{
        case 0: print("case 1")
        case 1: print("case 2")
        case 2: self.showLicensesController()
        default: break
        }

    }

    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "licenses"{
            print("Licenses")
        }
    }

}

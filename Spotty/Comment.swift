//
//  Comment.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/5/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import Foundation

class Comment: NSObject{
    var timeStamp: NSNumber?
    var comment: String?
    var userID: String?
    var userName: String?
    var profileImageURL: String?
    var postID: String? // Think of the postID as a foreign key of the Posts table.
}

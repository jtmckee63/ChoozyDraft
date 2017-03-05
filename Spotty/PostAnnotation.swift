//
//  PostAnnotation.swift
//  
//
//  Created by Cameron Eubank on 9/4/16.
//
//

import MapKit

//class PostAnnotation: MKPointAnnotation {
//    var post = Post()
//}

class PostAnnotation: NSObject, MKAnnotation {
    
    var post = Post()
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

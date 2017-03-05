//
//  MyAnnotation.swift
//  Spotty
//
//  Created by joseph mckee on 11/3/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import UIKit
import MapKit

class MyAnnotation: NSObject, MKAnnotation {
    var annotationView = MKPinAnnotationView()
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title: String!
    var place = Place()
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }

}

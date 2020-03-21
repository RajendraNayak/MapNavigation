//
//  ViewController.swift
//  MapNavigation
//
//  Created by Rajendra Nayak on 06/03/20.
//  Copyright © 2020 Rajendra Nayak. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var instructionLabel1: UILabel!
    @IBOutlet weak var routeMap: MKMapView!
    
    var mapRouteHelper: MapRouteHelper?
    var destination: MKMapItem?
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        return locationManager
    }()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.mapRouteHelper = MapRouteHelper(locationManager: self.locationManager, mapView: self.routeMap)
        self.mapRouteHelper?.onEnterRegion = {[weak self] instruction in
            self?.instructionLabel.text = instruction
        }
        self.mapRouteHelper?.onStartRegion = {[weak self] instruction in
            self?.instructionLabel1.text = instruction
        }
        
        self.config()
        print("chakali")
    }

    private func config() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addDestinationPoint(gestureRecognizer:)))
        self.routeMap.addGestureRecognizer(longGesture)
    }

    @objc func addDestinationPoint(gestureRecognizer: UIGestureRecognizer) {

        let touchPoint = gestureRecognizer.location(in: self.routeMap)
        let newCoordinates = self.routeMap.convert(touchPoint, toCoordinateFrom: self.routeMap)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        self.routeMap.removeAnnotations(self.routeMap.annotations)
        self.routeMap.addAnnotation(annotation)
        self.destination = MKMapItem(placemark: MKPlacemark(coordinate: newCoordinates))
        if let destination = self.destination {
            self.mapRouteHelper?.setDestination(destination: destination)
        }
    }
    
    @IBAction func Direction(_ sender: Any) {
        self.mapRouteHelper?.getDirections()
    }
    
    @IBAction func goBtnAction(_ sender: Any) {
        self.mapRouteHelper?.goNow()
    }
    
    @IBAction func settingAction(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                      
        let alert = UIAlertController(title: "Enter Region Radius", message: nil, preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = "\( appDelegate.regionRadius)"
            textField.keyboardType = .numberPad
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields?[0] {
                let radius = (textField.text! as NSString).doubleValue
                appDelegate.regionRadius = radius
            }
            
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}


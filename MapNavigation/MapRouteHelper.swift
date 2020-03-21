//
//  MapRouteHelper.swift
//  MapNavigation
//
//  Created by Rajendra Nayak on 06/03/20.
//  Copyright © 2020 Rajendra Nayak. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

typealias handler = (_ instruction :String) ->()
typealias completion = (_ instruction :String) ->()

class MapRouteHelper: NSObject{
    var locationManager: CLLocationManager
    var mapView: MKMapView!
    var userLocation: CLLocation?
    var destination: MKMapItem?
    //let regionRadius = 4.0
    var onEnterRegion: handler?
    var onStartRegion: completion?
    
    init(locationManager: CLLocationManager, mapView: MKMapView){
        self.locationManager = locationManager
        self.mapView = mapView
        super.init()
        self.configure()
    }
    
    func setDestination(destination: MKMapItem){
        self.destination = destination
    }
    
    private func configure(){
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.isZoomEnabled = true
        self.mapView.isScrollEnabled = true
        self.mapView.userTrackingMode = .followWithHeading

        self.locationManager.requestAlwaysAuthorization()
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    func getDirections() {
        guard let destination = self.destination else {
            print("Destination not found")
            return
        }
        guard let currentLocation = self.userLocation else {
            print("currentLocation not found")
            return
        }
        
        let request = MKDirections.Request()
        request.requestsAlternateRoutes = false
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate, addressDictionary: nil))
        request.destination = destination
        //request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: {(response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let response = response {
                    self.showRoute(response)
                }
            }
        })
    }
    
    func showRoute(_ response: MKDirections.Response) {
        if let route = response.routes.first {
            mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            for step in route.steps {
                print(step.distance)
                print(step.instructions)
                let str = "In \(step.distance) \n \(step.instructions)"
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: appDelegate.regionRadius, identifier: str)
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: step.polyline.coordinate, radius: appDelegate.regionRadius)
                self.mapView.addOverlay(circle)
                
            }
        }
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        
    }
    
    func goNow() {
        if let coordinate = userLocation?.coordinate {
            //let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 4.0, longitudinalMeters: 4.0)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0002, longitudeDelta: 0.0002))
            
            self.mapView.setRegion(region, animated: true)
           
        }
    }

}

extension MapRouteHelper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
           didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("region.identifier====\(region.identifier)")
        guard let cb = onStartRegion else {return}
        cb(region.identifier)
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("region.identifier====\(region.identifier)")
        self.locationManager.stopMonitoring(for: region)
        guard let cb = onEnterRegion else {return}
        cb(region.identifier)
    }
}

extension MapRouteHelper: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = UIColor.red
            circleRenderer.lineWidth = 1.0
            return circleRenderer
        }
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
}

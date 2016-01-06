//
//  VisitedTableViewController.swift
//  VCountries
//
//  Created by Eugene Chechkov on 6/3/15.
//  Copyright (c) 2015 Chechkov Eugene. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

class VisitedTableViewController: UIViewController,
NSXMLParserDelegate, UIGestureRecognizerDelegate {
    
    enum ViewType: Int {
        case Map, List, Visited, Planned
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var countries:[Country] = []
    var root:KMLRoot?
    
    var managedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if !Reachability.reachabilityForInternetConnection()!.isReachable() {
            self.reportIncedentErrorShow("Internet connection error", message:  "Could not connect to the internet")
        }
        
        
        mapView.delegate = self
        mapView.mapType = MKMapType.Standard
        mapView.showsUserLocation = false
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        
        setSegmentedControlAppearence()
        addGestureRecognizers()
        loadData()
    }
    
    func setSegmentedControlAppearence() {
        if let barFont = UIFont(name: "MavenProMedium", size: 14.0) {
            viewTypeSegmentedControl.setTitleTextAttributes([NSFontAttributeName:barFont], forState: UIControlState.Normal)
        }
    }
    
    func addGestureRecognizers() {
        let tgr = UILongPressGestureRecognizer(target: self, action: "handleGesture:")
        tgr.minimumPressDuration = 1.5
        tgr.delegate = self;
        mapView.addGestureRecognizer(tgr)
    }
    
    func loadData() {
        if root == nil {
            let countriesFilePath = NSBundle.mainBundle().pathForResource("countries_world", ofType: "kml")
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.root = KMLParser.parseKMLAtPath(countriesFilePath)
                let request = NSFetchRequest(entityName: "Country")
                request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                var results:[Country] = []
                do {
                    results = (try self.managedContext.executeFetchRequest(request)) as! [Country]
                } catch let error as NSError {
                    print("Could not update country \(error), \(error.userInfo)")
                }
                if !results.isEmpty {
                    self.countries = results
                    let countriesForOverlay = results.filter({$0.isVisited || $0.isPlanned})
                    if countriesForOverlay.count > 0 {
                        for country in countriesForOverlay {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.addOverlayForName(country.code)
                            })
                        }
                    }
                } else {
                    self.fillCountriesDataFromFile()
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    // self.showHelpMessage()
                    NSNotificationCenter.defaultCenter().postNotificationName("countriesLoaded", object: nil, userInfo: nil)
                    self.countries.sortInPlace({$0.name < $1.name})
                    // self.takeScreenShot()
                    self.tableView.reloadData()
                })
            })
        }
    }
    /*
    func takeScreenShot() {
    let options = MKMapSnapshotOptions()
    options.region = mapView.region
    options.size = mapView.frame.size
    options.scale = UIScreen.mainScreen().scale
    
    let tmpDir = NSTemporaryDirectory()
    let fileName = "sceenshot.png"
    
    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.startWithCompletionHandler { snapshot, error in
    guard let snapshot = snapshot else {
    print("Snapshot error: \(error)")
    return
    }
    
    let data = UIImagePNGRepresentation(snapshot.image)
    let path = (tmpDir as NSString).stringByAppendingPathComponent(fileName)
    data?.writeToFile(path, atomically: true)
    }
    }
    
    func showHelpMessage() {
    let alertController = UIAlertController(title: nil, message: "Please make a long press gesture on a country region to select/unselect it", preferredStyle: .Alert)
    
    let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
    
    alertController.addAction(cancelAction)
    
    self.presentViewController(alertController, animated: true, completion: nil)
    } */
    
    func fillCountriesDataFromFile() {
        let start = NSDate()
        if self.root != nil && self.root?.placemarks() != nil && self.countries.isEmpty{
            if let placemarks = self.root?.placemarks() as? [KMLPlacemark] {
                let entity = NSEntityDescription.entityForName("Country", inManagedObjectContext: self.managedContext)
                for placemark in placemarks {
                    if placemark.name != "West Bank" && placemark.name != "Gaza" && placemark.name != "Ashmore and Cartier Islands" {
                        
                        let country = Country(entity: entity!, insertIntoManagedObjectContext: self.managedContext)
                        
                        let plDescription = placemark.descriptionValue
                        let codeText = plDescription.componentsSeparatedByString(" : ")[0]
                        let code = codeText.stringByReplacingOccurrencesOfString("ISO_A2=", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        country.code = code
                        
                        let identifier = NSLocale.localeIdentifierFromComponents([NSLocaleCountryCode:code])
                        let locale = NSLocale.currentLocale()
                        let localizedCountryName = locale.displayNameForKey(NSLocaleIdentifier, value: identifier)
                        country.name = localizedCountryName != "99" ? localizedCountryName! : placemark.name
                        country.defaultName = placemark.name
                        self.countries.append(country)
                    }
                }
                do {
                    try self.managedContext.save()
                    let end = NSDate()
                    let timeInterval: Double = end.timeIntervalSinceDate(start); // <<<<< Difference in seconds (double)
                    
                    print("Time to evaluate problem \(timeInterval) seconds")
                } catch let error as NSError {
                    print("Could not update country \(error), \(error.userInfo)")
                }
            }
            
        }
    }
    
    func getGeometryByCountryName(countryName: String) -> [KMLAbstractGeometry]? {
        if root != nil && root?.placemarks() != nil {
            let placemarksWithName = (root?.placemarks().filter({
                ($0 as! KMLPlacemark).name == countryName
                }
                )) as? [KMLPlacemark]
            
            if placemarksWithName != nil && !(placemarksWithName!.isEmpty) {
                let placemark = placemarksWithName![0]
                let geometry = placemark.geometry as! KMLMultiGeometry
                return geometry.geometries as? [KMLAbstractGeometry]
            }
        }
        return nil
    }
    
    func getGeometryByCountryCode(countryCode: String) -> [KMLAbstractGeometry]? {
        if root != nil && root?.placemarks() != nil {
            let placemarksWithName = (root?.placemarks().filter({
                let plc = ($0 as! KMLPlacemark)
                let plDescription = plc.descriptionValue
                let codeText = plDescription.componentsSeparatedByString(" : ")[0]
                let code = codeText.stringByReplacingOccurrencesOfString("ISO_A2=", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                return code == countryCode
                }
                )) as? [KMLPlacemark]
            
            if placemarksWithName != nil && !(placemarksWithName!.isEmpty) {
                let placemark = placemarksWithName![0]
                let geometry = placemark.geometry as! KMLMultiGeometry
                return geometry.geometries as? [KMLAbstractGeometry]
            }
        }
        return nil
    }
    
    func addCountryOverlayWithName(name: String, geometries:[KMLAbstractGeometry]) {
        for geometry in geometries {
            if let polygon = geometry as? KMLPolygon {
                let outerCoordinates = polygon.outerBoundaryIs.coordinates
                if outerCoordinates.count > 0 {
                    var coords:[CLLocationCoordinate2D] = []
                    for coordinate in outerCoordinates {
                        coords.append(CLLocationCoordinate2DMake(Double(coordinate.latitude!), Double(coordinate.longitude!)))
                    }
                    
                    let polygon = MKPolygon(coordinates: &coords, count: coords.count)
                    polygon.title = name
                    self.mapView.addOverlay(polygon)
                }
            }
        }
    }
    
    
    
    func addOverlayForName(name: String) {
        self.addCountryOverlayWithName(name, geometries:self.getGeometryByCountryCode(name)!)
    }
    
    func removeOverlayForName(name: String) {
        let overlays = self.mapView.overlays.filter({($0 as! MKPolygon).title == name})
        self.mapView.removeOverlays(overlays)
    }
    
    @IBAction func viewTypeSegmentedControlChanged(sender: UISegmentedControl) {
        switch getSelectedViewType() {
        case .Map:
            self.mapView.hidden = false
            self.tableView.hidden = true
        case .List, .Planned, .Visited:
            self.mapView.hidden = true
            self.tableView.hidden = false
            self.tableView.reloadData()
        }
    }
    
    func getSelectedViewType() -> ViewType {
        return ViewType(rawValue: self.viewTypeSegmentedControl.selectedSegmentIndex)!
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleGesture(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(self.mapView)
        let touchMapCoordinates = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        let location = CLLocation(latitude: touchMapCoordinates.latitude, longitude: touchMapCoordinates.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) in
            if (error != nil) {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            if let pm = placemarks {
                for placemark in pm
                {
                    if let code = placemark.ISOcountryCode {
                        self.chooseCountryType(code, pointOfClick: touchPoint)
                    }
                }
            }
        })
    }
    
    func chooseCountryType(code: String, pointOfClick: CGPoint) {
        
        let countriesSelected = self.countries.filter({$0.code == code})
        
        if countriesSelected.count > 0 {
            let country = countriesSelected[0]
            showCountryTableActionAlertView(country, code: code, pointOfClick: pointOfClick)
        }
    }
    
    func showCountryTableActionAlertView(country: Country, code: String, pointOfClick: CGPoint) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let visitAction = UIAlertAction(title: "I've been here", style: .Default) { (action:UIAlertAction) -> Void in
            
            if country.isPlanned {
                self.countries.filter({$0.code == code})[0].isPlanned = false
                self.countries.filter({$0.code == code})[0].isVisited = true
                self.removeOverlayForName(code)
                self.addOverlayForName(code)
            } else if !country.isPlanned && !country.isVisited {
                self.countries.filter({$0.code == code})[0].isVisited = true
                self.addOverlayForName(code)
            }
        }
        
        let planAction = UIAlertAction(title: "I'm planning to visit", style: .Default) { (action:UIAlertAction) -> Void in
            
            if country.isVisited {
                self.countries.filter({$0.code == code})[0].isVisited = false
                self.countries.filter({$0.code == code})[0].isPlanned = true
                self.removeOverlayForName(code)
                self.addOverlayForName(code)
            } else if !country.isPlanned && !country.isVisited {
                self.countries.filter({$0.code == code})[0].isPlanned = true
                self.addOverlayForName(code)
            }
        }
        
        
        let deselectAction = UIAlertAction(title: "Deselect", style: .Default) { (action:UIAlertAction) -> Void in
            
            if country.isPlanned || country.isVisited {
                self.countries.filter({$0.code == code})[0].isPlanned = false
                self.countries.filter({$0.code == code})[0].isVisited = false
                self.removeOverlayForName(code)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        
        if country.isVisited {
            alertController.addAction(planAction)
            alertController.addAction(deselectAction)
        } else if country.isPlanned {
            alertController.addAction(visitAction)
            alertController.addAction(deselectAction)
        } else {
            alertController.addAction(visitAction)
            alertController.addAction(planAction)
        }
        
        alertController.addAction(cancelAction)
        
        /*
        UIPopoverPresentationController *alertPopoverPresentationController = alertController.popoverPresentationController;
        UIButton *imagePickerButton = (UIButton*)sender;
        alertPopoverPresentationController.sourceRect = imagePickerButton.frame;
        alertPopoverPresentationController.sourceView = self.view;
        
        [self showDetailViewController:alertController sender:sender];
        */
        let alertPopoverPresentationController = alertController.popoverPresentationController
        alertPopoverPresentationController?.sourceRect = CGRect(origin: pointOfClick, size: CGSize(width: 10, height: 10))
        alertPopoverPresentationController?.sourceView = self.view
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowInfo" {
            let infoVC = segue.destinationViewController as! InformationViewController
            infoVC.delegate = self
            infoVC.countries = self.countries
        }
    }
    
    func reportIncedentErrorShow(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension VisitedTableViewController: MKMapViewDelegate {
    
    func mapViewDidFailLoadingMap(mapView: MKMapView, withError error: NSError) {
        print("Map error \(error), \(error.userInfo)")
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        if (overlay is MKPolygon) {
            let country = countries.filter({$0.code == overlay.title!})[0]
            let pr = MKPolygonRenderer(overlay: overlay)
            pr.strokeColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            if country.isVisited {
                pr.fillColor = UIColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.5)
            } else if country.isPlanned {
                pr.fillColor = UIColor(red: 0.8, green: 0.0, blue: 0.2, alpha: 0.5)
            } else {
                pr.fillColor = UIColor.clearColor()
            }
            pr.lineWidth = 0.1;
            return pr;
        }
        return MKPolygonRenderer(overlay: overlay)
    }
}

extension VisitedTableViewController:  UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch getSelectedViewType() {
        case .Map:
            return 0
        case .List:
            return countries.filter({$0.isVisited == false && $0.isPlanned == false}).count
        case .Visited:
            return countries.filter({$0.isVisited == true}).count
        case .Planned:
            return countries.filter({$0.isPlanned == true}).count
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CountryCell", forIndexPath: indexPath) as! CountryTableViewCell
        
        var country:Country? = nil
        
        switch getSelectedViewType() {
        case .Map:
            country = nil
        case .List:
            country = countries.filter({$0.isVisited == false && $0.isPlanned == false})[indexPath.row]
        case .Visited:
            country = countries.filter({$0.isVisited == true})[indexPath.row]
        case .Planned:
            country = countries.filter({$0.isPlanned == true})[indexPath.row]
        }
        if country != nil {
            cell.nameLabel.text = country!.name
            cell.flagImageView.image = UIImage(named: country!.defaultName)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var country:Country? = nil
        switch getSelectedViewType() {
        case .Map:
            return
        case .List:
            country = countries.filter({$0.isVisited == false && $0.isPlanned == false})[indexPath.row]
        case .Visited:
            country = countries.filter({$0.isVisited == true})[indexPath.row]
        case .Planned:
            country = countries.filter({$0.isPlanned == true})[indexPath.row]
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        showCountryMapActionAlertView(country)
    }
    
    func showCountryMapActionAlertView(country: Country?) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let visitAction = UIAlertAction(title: "I've been here", style: .Default) { (action:UIAlertAction) -> Void in
            
            switch self.getSelectedViewType() {
            case .Map, .Visited:
                return
            case .List:
                self.countries.filter({$0.name == country!.name})[0].isVisited = true
                self.tableView.reloadData()
                self.addOverlayForName(country!.code)
            case .Planned:
                self.countries.filter({$0.name == country!.name})[0].isVisited = true
                self.countries.filter({$0.name == country!.name})[0].isPlanned = false
                self.tableView.reloadData()
                self.removeOverlayForName(country!.code)
                self.addOverlayForName(country!.code)
            }
            
        }
        
        let planAction = UIAlertAction(title: "I'm planning to visit", style: .Default) { (action:UIAlertAction) -> Void in
            switch self.getSelectedViewType() {
            case .Map, .Planned:
                return
            case .List:
                self.countries.filter({$0.name == country!.name})[0].isPlanned = true
                self.tableView.reloadData()
                self.addOverlayForName(country!.code)
            case .Visited:
                self.countries.filter({$0.name == country!.name})[0].isPlanned = true
                self.countries.filter({$0.name == country!.name})[0].isVisited = false
                self.tableView.reloadData()
                self.removeOverlayForName(country!.code)
                self.addOverlayForName(country!.code)
            }
        }
        
        let deselectAction = UIAlertAction(title: "Deselect", style: .Default) { (action:UIAlertAction) -> Void in
            switch self.getSelectedViewType() {
            case .Map, .List:
                return
            case .Visited, .Planned:
                self.countries.filter({$0.name == country!.name})[0].isPlanned = false
                self.countries.filter({$0.name == country!.name})[0].isVisited = false
                self.tableView.reloadData()
                self.removeOverlayForName(country!.code)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        switch getSelectedViewType() {
        case .Map:
            return
        case .List:
            alertController.addAction(visitAction)
            alertController.addAction(planAction)
        case .Visited:
            alertController.addAction(planAction)
            alertController.addAction(deselectAction)
        case .Planned:
            alertController.addAction(visitAction)
            alertController.addAction(deselectAction)
        }
        
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
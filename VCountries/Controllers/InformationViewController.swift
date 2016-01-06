//
//  InformationViewController.swift
//  VCountries
//
//  Created by Eugene Chechkov on 6/8/15.
//  Copyright (c) 2015 Chechkov Eugene. All rights reserved.
//

import UIKit
import Social
import FBSDKCoreKit
import FBSDKShareKit

class InformationViewController: UIViewController {
    
    @IBOutlet weak var totalCountriesLbl: UILabel!
    @IBOutlet weak var visitedCountriesLbl: UILabel!
    @IBOutlet weak var plannedCountriesLbl: UILabel!
    
    @IBOutlet weak var twitterBtn: UIButton!
    @IBOutlet weak var facebookBtn: UIButton!
    
    var delegate:VisitedTableViewController? = nil
    
    var countries:[Country] = [] {
        didSet {
            if self.isViewLoaded() {
                fillLabelsWithInfo()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "countriesLoaded:", name: "countriesLoaded", object: nil)
        
        if !countries.isEmpty {
            fillLabelsWithInfo()
        }
    }
    
    func countriesLoaded(notification: NSNotification) {
        if self.delegate != nil {
            self.countries = self.delegate!.countries
        }
    }
    
    func fillLabelsWithInfo() {
        self.totalCountriesLbl.text = "Total countries : \(countries.count)"
        
        let visitedCount = countries.filter({ $0.isVisited == true }).count
        let visitedPercent:Double = countries.isEmpty == true ? 0.0 : Double(round(100*(Double(visitedCount) * 100 / Double(countries.count)))/100)
        
        self.visitedCountriesLbl.text = "Visited : \(visitedCount) (\(visitedPercent)%)"
        
        let plannedCount = countries.filter({ $0.isPlanned == true }).count
        let plannedPercent:Double = countries.isEmpty == true ? 0.0 : Double(round(100*(Double(plannedCount) * 100 / Double(countries.count)))/100)
        
        self.plannedCountriesLbl.text = "Planned : \(plannedCount) (\(plannedPercent)%)"
        
    }
    
    func getMessageText() -> String{
        let countriesVisited = self.countries.filter({$0.isVisited == true})
        let countriesPlanned = self.countries.filter({$0.isPlanned == true})
        
        var text = self.totalCountriesLbl.text! + "\n" + self.visitedCountriesLbl.text! + "\n"
        for country in countriesVisited {
            text += country.name + "\n"
        }
        text += self.plannedCountriesLbl.text!
        for country in countriesPlanned {
            text += country.name + "\n"
        }
        return text
    }
    /*
    @IBAction func postToTwitter(sender: UIButton) {
    self.twitterBtn.enabled = false
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
    let controller = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    
    controller.setInitialText(getMessageText())
    self.presentViewController(controller, animated:true, completion:{ self.twitterBtn.enabled = true })
    }
    else {
    let alertController = UIAlertController(title: "Sorry", message: "You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup", preferredStyle: .Alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    self.presentViewController(alertController, animated: true, completion: { self.twitterBtn.enabled = true })
    }
    }
    
    
    @IBAction func postToFacebook(sender: UIButton) {
    
    self.facebookBtn.enabled = false
    
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
    
    let photo : FBSDKSharePhoto = FBSDKSharePhoto()
    
    let tmpDir = NSTemporaryDirectory()
    let fileName = "sceenshot.png"
    let path = (tmpDir as NSString).stringByAppendingPathComponent(fileName)
    
    let image = UIImage(contentsOfFile: path)
    photo.image = image
    photo.userGenerated = true
    let content : FBSDKSharePhotoContent = FBSDKSharePhotoContent()
    content.photos = [photo]
    let dialog = FBSDKShareDialog()
    dialog.fromViewController = self
    dialog.shareContent = content
    dialog.mode = FBSDKShareDialogMode.ShareSheet
    dialog.show()
    /*
    
    let controller = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
    controller.completionHandler = { (result: SLComposeViewControllerResult) in
    controller.dismissViewControllerAnimated(true, completion: nil)
    }
    controller.setInitialText(getMessageText())
    // controller.addImage(UIImage(contentsOfFile: "path/to/snapshot.png"))
    //   controller.addURL(NSURL(fileURLWithPath: "path/to/snapshot.png"))
    self.presentViewController(controller, animated:true, completion:{ self.facebookBtn.enabled = true }) */
    }
    else {
    let alertController = UIAlertController(title: "Sorry", message: "You can't send a Facebook message right now, make sure your device has an internet connection and you have at least one Facebook account setup", preferredStyle: .Alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    self.presentViewController(alertController, animated: true, completion: { self.facebookBtn.enabled = true })
    }
    }
    */
}

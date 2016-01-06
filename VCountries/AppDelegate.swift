//
//  AppDelegate.swift
//  VCountries
//
//  Created by Eugene Chechkov on 6/3/15.
//  Copyright (c) 2015 Chechkov Eugene. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var activityIndicatorView:UIActivityIndicatorView!
    var reach: Reachability?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        customizeAppearance()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "countriesLoaded:", name: "countriesLoaded", object: nil)
        
        checkReachability()
        createActivityIndicator()
        activityIndicatorView.startAnimating()
        
        return true
    }
    
    func customizeAppearance() {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.0/255.0, green: 82.0/255.0, blue: 124.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().translucent = false
        if let barFont = UIFont(name: "MavenProMedium", size: 22.0) {
            UINavigationBar.appearance().titleTextAttributes =
                [NSForegroundColorAttributeName:UIColor.whiteColor(), NSFontAttributeName:barFont]
        }
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    func createActivityIndicator() {
        
        if let mainView = self.window?.rootViewController?.view {
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle:.Gray)
            activityIndicatorView.transform = CGAffineTransformMakeScale(1.5,1.5)
            activityIndicatorView.center = CGPoint(x: mainView.center.x, y: mainView.center.y)
            activityIndicatorView.hidesWhenStopped = true
            mainView.addSubview(activityIndicatorView)
        }
    }
    
    func countriesLoaded(notification: NSNotification) {
        if activityIndicatorView.isAnimating() {
            activityIndicatorView.stopAnimating()
        }
    }
    
    func checkReachability(){
        
        self.reach = Reachability.reachabilityForInternetConnection()
        
        if !self.reach!.isReachable() {
            self.reportIncedentErrorShow("Internet connection error", message:  "Could not connect to the internet")
        }
        
        self.reach!.unreachableBlock = {
            (let reach: Reachability!) -> Void in
            self.reportIncedentErrorShow("Internet connection error", message:  "Could not connect to the internet")
        }
        
        self.reach!.startNotifier()
    }
    
    func reportIncedentErrorShow(title: String, message: String){
        if let navVC = self.window?.rootViewController as? UINavigationController {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            navVC.visibleViewController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("VCountries", withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("VCountries.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption: true])
            return coordinator
        } catch let error as NSError {
            coordinator = nil
            NSLog("Unresolved error \(error), \(error.userInfo)")
            return coordinator
        }
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext! = {
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        
    }()
    
    func saveContext() {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}


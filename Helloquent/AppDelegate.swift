//
//  AppDelegate.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import NMAKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        let kHelloMapAppID = "gkoto48G36qGguuFnFgY"
        let kHelloMapAppCode = "kpTvxHHLmOn4zlAdkwGH4Q"
        let kHelloMapLicenseKey = "f/9Sx9/I4ijmVhVRNrA4ZtfdqY3j6UQ+WkDMxQfBTdfXd3Rc+w9OFpujNGm1jI4P8u7LshPTD1kAFyaGFL20rEGxe7bL9BTNlCNz11FSfVESkMtn24fhzK/42XG9C5Ye9/2p7+U5VbMZAutyvcl/lnyAO27/MsZnAh7laQUZETpXGFgxahWKx1LVMdZq0BKaEKIJWbeMiA3pKHS8zt1SbWApghwUgyYIVSzx0K0sUx9Bu4e3yi9p996M6Cx+mU4RcLD/7KWwZ+bCZsNKhkdn1cl4afiVJXi68ZIoG75We/81mZXnFFgip/1l46eaWstqWqMJ99bWbxZDsxCkX8htYeYJarkRMfOaEyc1keZ8VRUAdBuWm8fXcpZojmqPvm6kUlW1J2mFlrc/iLTGzAP/6AjxSHAZZknY1Whwf8sJf1w6/eO/psoZ78n3ZWOjgPVtWNawlryWbtk1F07Dd98uth5B5eXSXZZlBRKlKMjRjiSE6qdHgCnK+nnkAXp85OHj9b+hAEwRclKzr6TqOP3ap7uFMZHJPsZFobN5hOROKovf0k/o0QRrCyEWln/stZ4whI6+yVyoFqY/KxB1ybXvpn9nBIhD2jvptYRJdDcDr7eAJxXeI2Uklsn7gYj1sslQktvMov1jreCl2DluPU9yVf0oZCemOVFf6ZGRvAC0kls="
        
        let error =  NMAApplicationContext.setAppId(kHelloMapAppID,
                                                    appCode: kHelloMapAppCode,
                                                    licenseKey: kHelloMapLicenseKey)
        assert(error == NMAApplicationContextError.none)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled: Bool = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: UIApplicationOpenURLOptionsKey.sourceApplication.rawValue, annotation: UIApplicationOpenURLOptionsKey.annotation)
        return handled
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        NotificationCenter.default.post(name: NSNotification.Name("ResignActiveNotification"), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: NSNotification.Name("BecomeActiveNotification"), object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}



//
//  AppDelegate.swift
//  Helloquent
//
//  Created by Morgan Trudeau on 2017-12-21.
//  Copyright © 2017 Morgan Trudeau. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseMessaging
import FBSDKCoreKit
import NMAKit
import CoreData
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
 
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Messaging.messaging().delegate = self
        Fabric.with([Crashlytics.self])
        
        let kHelloMapAppID = "WGItU7a0q8159FCZOAW6"
        let kHelloMapAppCode = "5IMS7GYiV-dxl2Jb2eT-FQ"
        NMAApplicationContext.set(appId: kHelloMapAppID, appCode: kHelloMapAppCode)
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {

    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled: Bool = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: UIApplicationOpenURLOptionsKey.sourceApplication.rawValue, annotation: UIApplicationOpenURLOptionsKey.annotation)
        return handled
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Print full message.
        let roomID = userInfo["roomID"] as! String?
        let senderID = userInfo["senderID"] as! String
        let roomName = userInfo["roomName"] as! String?
        let chatID = userInfo["chatID"] as! String?
        if senderID != AuthProvider.Instance.userID() {
            if (application.applicationState == UIApplicationState.inactive || application.applicationState == UIApplicationState.background) {
                let visibleVC = (application.topMostViewController())!
                if chatID != nil {
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
                    let roomsContainerNav = storyboard.instantiateViewController(withIdentifier: "RoomsContainerNav") as! UINavigationController
                    let chatsNav = storyboard.instantiateViewController(withIdentifier: "PersonalChatsNav") as! UINavigationController
                    let mapNav = storyboard.instantiateViewController(withIdentifier: "MapNav") as! UINavigationController
                    let profileNav = storyboard.instantiateViewController(withIdentifier: "ProfileNav") as! UINavigationController
                    
                    tabBarVC.viewControllers = [roomsContainerNav, chatsNav, mapNav, profileNav]
                    self.window?.rootViewController = tabBarVC
                    
                    let personalChatVC = storyboard.instantiateViewController(withIdentifier: "PersonalChatVC") as! PersonalChatVC
                    personalChatVC.m_receiverUserID = senderID
                    personalChatVC.m_currentChatID = chatID!
                    tabBarVC.selectedIndex = 1
                    chatsNav.pushViewController(personalChatVC, animated: false)
                    chatsNav.navigationBar.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
                } else {
                    let room = Room(name: roomName!, description: "", id: roomID!, password: "", likes: 0)
                    DBProvider.Instance.m_currentRoom = room
                    if !visibleVC.isKind(of: ChatVC.classForCoder()) {
                        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
                        let roomsContainerNav = storyboard.instantiateViewController(withIdentifier: "RoomsContainerNav") as! UINavigationController
                        let chatsNav = storyboard.instantiateViewController(withIdentifier: "PersonalChatsNav") as! UINavigationController
                        let mapNav = storyboard.instantiateViewController(withIdentifier: "MapNav") as! UINavigationController
                        let profileNav = storyboard.instantiateViewController(withIdentifier: "ProfileNav") as! UINavigationController
                        
                        tabBarVC.viewControllers = [roomsContainerNav, chatsNav, mapNav, profileNav]
                        self.window?.rootViewController = tabBarVC
                        
                        let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
                        roomsContainerNav.pushViewController(chatVC, animated: false)
                        roomsContainerNav.navigationBar.tintColor = UIColor(red: 133/255, green: 51/255, blue: 1, alpha: 1)
                    }
                }
            } else {
                if roomID != nil {
                    NotificationCenter.default.post(name: NSNotification.Name("SetBadge"), object: nil, userInfo: ["room_id": roomID!])
                    CacheStorage.Instance.increaseCellNotifications(id: roomID!)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("SetBadge"), object: nil, userInfo: ["chat_id": chatID!])
                    CacheStorage.Instance.increaseCellNotifications(id: chatID!)
                    DBProvider.Instance.getUser(id: AuthProvider.Instance.userID(), completion: nil)
                }
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        NotificationCenter.default.post(name: NSNotification.Name("ResignActiveNotification"), object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: NSNotification.Name("BecomeActiveNotification"), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}


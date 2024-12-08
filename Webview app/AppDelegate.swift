//
//  AppDelegate.swift
//  Webview app
//
//  Created by Toshit Garg on 08/05/22.
//

import UIKit

import OneSignalFramework
var globalId: String? = "0"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // Use Firebase library to configure APIs
            
            // OneSignal initialization
            OneSignal.initialize("onesignal_ID", withLaunchOptions: launchOptions)
            
            SettingsManager.shared.launchCount += 1
            IAPManager.shared.compleateTransations()
            globalId = OneSignal.User.pushSubscription.id
            print("GlobalId in AppDelegate: \(String(describing: globalId))")
            
            return true
        }
        
        // MARK: UISceneSession Lifecycle
        
        func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
            // Called when a new scene session is being created.
            // Use this method to select a configuration to create the new scene with.
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
        
        func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
            // Called when the user discards a scene session.
            // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
            // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let urlString = userActivity.webpageURL?.absoluteString {
            AppDelegate.handleUrlString(urlString, window: window)
            return true
        }
        
        return false
    }
    
    static func handleUrlString(_ urlString: String, window: UIWindow?) {
        SettingsManager.websiteUrl = urlString
        
        if let rootVC = window?.rootViewController, rootVC.presentedViewController is ViewController2 {
            let vc = rootVC.presentedViewController as! ViewController2
            
            let urlRequest = URLRequest(url: URL(string: SettingsManager.websiteUrl)!)
            vc.webView.load(urlRequest)
        }
    }
    
}

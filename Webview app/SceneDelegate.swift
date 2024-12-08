//
//  SceneDelegate.swift
//  Webview app
//
//  Created by Toshit Garg on 08/05/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        
        if let userActivity = connectionOptions.userActivities.first, userActivity.activityType == NSUserActivityTypeBrowsingWeb, let urlString = userActivity.webpageURL?.absoluteString {
            SettingsManager.websiteUrl = urlString
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if UserDefaults.standard.bool(forKey: "isSubsribed") {
            if !UserDefaults.standard.bool(forKey: "isShowExpiryUrl") {
                IAPManager.shared.setupStorekit { result in
                    if let res = result {
                        if res == "0" {
                            UserDefaults.standard.setValue(true, forKey: "isShowExpiryUrl")
                            SettingsManager.websiteUrl = SettingsManager.shared.expiryUrl
                            setupRootVC()
                        } else {
                            setupRootVC()
                        }
                    }
                }
            } else {
                setupRootVC()
            }
        } else {
            setupRootVC()
        }
        
        func setupRootVC() {
            DispatchQueue.main.async {
                if let rootVC = self.window?.rootViewController, rootVC is ViewController {
                    let vc = rootVC as! ViewController
                    vc.startProcess()
                }
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Reveive deep link after iOS 13
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let urlString = userActivity.webpageURL?.absoluteString {
            AppDelegate.handleUrlString(urlString, window: window)
        }
    }
}


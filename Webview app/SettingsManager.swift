import Foundation
import UIKit
import UserNotifications
import OneSignalFramework

import AdSupport
import AppTrackingTransparency

class SettingsManager: NSObject {
    //singleton
    static let shared = SettingsManager()
    
    //static keys
    static let launchCountKey = "@SettingsManager.launchCountKey#"
    static let expiryUrlKey = "@SettingsManager.expiryUrlKey#"
    
    //save to userdefoults lounchCount
    var launchCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: SettingsManager.launchCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsManager.launchCountKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    //save to userdefoults expiryUrl
    var expiryUrl: String {
        get {
            return UserDefaults.standard.string(forKey: SettingsManager.expiryUrlKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsManager.expiryUrlKey)
            UserDefaults.standard.synchronize()
        }
    }

    //color for splash screen
    var splashBackgroundColour: UIColor = .myControlBackground(dark: "FFFFFF", light: "FFFFFF")
    //teheme color
    var themeColour: UIColor = .myControlBackground(dark: "FFFFFF", light: "000000")
    //text color
    var textColour: UIColor = .myControlBackground(dark: "FFFFFF", light: "FFFFFF")
    //refresh color on top side webview
    var refreshIndicatorTextColor: UIColor = .myControlBackground(dark: "FFFFFF", light: "FFFFFF")
    //center loading inciator color
    var loadingIndicatorColor: UIColor = .myControlBackground(dark: "FFFFFF", light: "FFFFFF")
    
    //boolens for webview setup
    var shouldAppendOneSignalId = false;
    var shouldAppendLaunchNumber = false;
    var shouldAppenAppFlag = false;
    var shouldShowLoadingIcon = true;
    var shouldRequestUDID = false;
    var pullToRefreshEnabled = true;
    var openExtranalUrlInBrowser = false
    
    //unique ID
    var udid = ""
    
    //domains in url
    let allowDomains: [String] = [
    "https://www.facebook.com",
    "https://www.instagram.com"
];
    
    //alert button & titles messages
    let firstLaunchMessage = ""
    let firstLaunchButtonText = "OK"
    
    //internet error alert titles
    let internetErrorTitle = "Internet is not available"
    let internetErrorMessage = "There is no internet connection, please check you connection and try again."
    let internetErrorExitButtonText = "yes"
    let internetErrorRetryButtonText = "No"
    
    //payment allert succes
    let setSuccessMessage = "Call payment successful url failed."
    let paymentSuccesButtonText = "OK"

    //in app fail alert message
    let inAppPurchasesFailedMessage = "In app purchases failed."
    let inAppPurchasesFailedButtonText = "OK"
    let requestPushCount = 3
    
    //web view base url

    static var websiteUrl = "https://defectionradio.com/"
}

extension SettingsManager {
    func checkPushAuthorizationWith(_ viewController: UIViewController, completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // If authorization status is not determined, request push authorization
                requestPushAuthorizationWith(viewController, completion: completion)
                break

            case .authorized:
                // If authorization status is authorized, set the delegate and call the completion
                UNUserNotificationCenter.current().delegate = self
                completion()
                break

            default:
                // If not determined or authorized, and certain conditions are met
                if self.launchCount % self.requestPushCount == 0 {
                    // Request permission using OneSignal if specific conditions are met
                    OneSignal.Notifications.requestPermission({ accepted in
                        print("User accepted notifications: \(accepted)")
                        completion()
                    }, fallbackToSettings: true)
                } else {
                    // Call the completion if conditions are not met
                    completion()
                }
                break
            }
        }

        
        func requestPushAuthorizationWith(_ viewController: UIViewController, completion: @escaping () -> Void) {
            // Set the delegate to self (assuming the delegate is implemented in the same object)
            UNUserNotificationCenter.current().delegate = self
            
            // Request push notification authorization with options for alert, sound, and badge
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                // Print the result of the authorization request and any error description
                print("Request push authorization result: \(granted)" + (error != nil ? "error: \(error!.localizedDescription)" : ""))
                
                // Call the completion closure after the authorization request
                completion()
            }
        }

    }
    
    func requestUdid(_ completion: @escaping () -> Void) {
        if (!shouldRequestUDID) {
            completion()
            return;
        }
        
        if #available(iOS 14, *) {
            // Check for iOS 14 or later
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                // If tracking is authorized, get the advertising identifier and call the completion
                self.udid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                completion()
            } else {
                // If tracking is not authorized or undetermined, request tracking authorization
                ATTrackingManager.requestTrackingAuthorization { [self] status in
                    DispatchQueue.main.async {
                        // Handle the authorization status
                        switch status {
                        case .authorized:
                            // If tracking is authorized, get the advertising identifier
                            self.udid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                            break
                        case .denied, .notDetermined, .restricted:
                            // Handle other authorization statuses if needed
                            break
                        default:
                            break
                        }

                        // Call the completion
                        completion()
                    }
                }
            }
        } else {
            // For iOS versions earlier than 14
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                // If advertising tracking is enabled, get the advertising identifier
                udid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
            
            // Call the completion
            completion()
        }

    }
}

extension SettingsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Specify the presentation options for the notification
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract the user info dictionary from the notification
        if let userInfo = response.notification.request.content.userInfo as Dictionary? {
            // get push info dictionary
        }
        // Call the completion handler when you're done processing the notification response
        completionHandler()
    }
}

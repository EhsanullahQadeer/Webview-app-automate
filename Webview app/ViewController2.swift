import UIKit
import WebKit
import WKDownloadHelper
import AppTrackingTransparency
class ViewController2: UIViewController,WKNavigationDelegate, UIScrollViewDelegate, WKUIDelegate{
    
    @IBOutlet weak var Loading: UILabel!
    var refController:UIRefreshControl = UIRefreshControl()
  
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var webView: WKWebView!
  
    var downloadHelper: WKDownloadHelper!

    var urlstring: String = "https://defectionradio.com/"
    var productID = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup Loading & activityIndicator colors
        Loading.textColor = SettingsManager.shared.loadingIndicatorColor
        activityIndicator.color = SettingsManager.shared.loadingIndicatorColor
        
        let baseUrlString = urlstring

        // initilize
        UIApplication.shared.isIdleTimerDisabled = false
        if var components = URLComponents(string: baseUrlString), let url = components.url  {
            // Create an array to store query items
            var queryItems: [URLQueryItem] = []
            // If there are existing percent encoded query items, append them to the array
            if let items = components.percentEncodedQueryItems {
                queryItems.append(contentsOf: items)
            }
            // Conditionally append query items based on settings
            if SettingsManager.shared.shouldAppendOneSignalId {
                queryItems.append(URLQueryItem(name: "OneSignalid", value: globalId))
            }
            if SettingsManager.shared.shouldAppendLaunchNumber {
                queryItems.append(URLQueryItem(name: "launchnois", value: "\(SettingsManager.shared.launchCount)"))
            }
            if SettingsManager.shared.shouldAppenAppFlag {
                queryItems.append(URLQueryItem(name: "app", value: "true"))
            }
            if SettingsManager.shared.shouldRequestUDID && SettingsManager.shared.udid.count > 0 {
                queryItems.append(URLQueryItem(name: "getudid", value: SettingsManager.shared.udid))
            }
            // Update the URL components with the new query items
            components.percentEncodedQueryItems = queryItems
            // Create a URLRequest with the updated URL
            let urlRequest = URLRequest(url: components.url ?? url)
            // Load the URLRequest into the WKWebView
            webView.load(urlRequest)
            // Start some process (not defined in the provided code)
            startProcess()
        } else {
            // Handle the case where the URL is invalid
            print("Invalid URL")
            // Start some process (not defined in the provided code)
            startProcess()
        }
    }
    
    func startProcess() {
        // Set the navigation delegate, UI delegate, and scroll view delegate to self
        webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.scrollView.delegate = self

        // Configure and add an activity indicator
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        Loading.isHidden = true
        
        // Set a custom user agent for the WKWebView
        webView.customUserAgent = ""

        // Check if pull-to-refresh is enabled in settings
        if SettingsManager.shared.pullToRefreshEnabled {
            // Adjust the bounds of the refresh control
            refController.bounds =  CGRect.init(x: 0.0, y: 50.0, width: refController.bounds.size.width, height: refController.bounds.size.height)
            // Add a target for the pull-to-refresh action
            refController.addTarget(self, action: #selector(self.mymethodforref(refresh:)), for: .valueChanged)
            // Set the attributed title for the refresh control
            let attributes = [NSAttributedString.Key.foregroundColor: SettingsManager.shared.refreshIndicatorTextColor]
            refController.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
            // Set the refresh control color
            refController.tintColor = SettingsManager.shared.refreshIndicatorTextColor
            // Add the refresh control to the WKWebView's scroll view
            webView.scrollView.addSubview(refController)
        }
    }


    func captureScreenShot() {
        // Begin an image context with the size of the view
        UIGraphicsBeginImageContext(view.frame.size)
        // Check if a context is successfully created
        if let context = UIGraphicsGetCurrentContext() {
            // Render the current view's layer into the context
            view.layer.render(in: context)
            // Get the image from the current context
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                // End the image context
                UIGraphicsEndImageContext()
                // Save the captured image to the device's photo album
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }

    func callShare(shareUrl: URL) {
        // Create an activity view controller with the share URL
        let activityVC = UIActivityViewController(activityItems: [shareUrl], applicationActivities: nil)
        // Set the presentation style of the activity view controller
        activityVC.modalPresentationStyle = .fullScreen
        // Exclude specific share types, in this case, AirDrop
        activityVC.excludedActivityTypes = [.airDrop]
        // Completion handler for the activity view controller
        activityVC.completionWithItemsHandler = { (type, flag, array, error) -> Void in
            // Check if sharing was successful
            if flag == true {
                print("Share succeeded")
            } else {
                // Sharing failed or was canceled
                print("Share failed")
            }
        }
        // Present the activity view controller
        self.present(activityVC, animated: true, completion: nil)
    }

    
    func clearCache(_ completion: (() -> Void)? = nil) {
        // clear special data type of cache
//        let websiteDataTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeCookies]
        // clear all cache
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        let dateFrom = Date.init(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
            if (completion != nil) {
                completion!();
            }
        }
    }
    
    func showLoading() {
        // Check if the loading icon should be shown based on the setting
        if SettingsManager.shared.shouldShowLoadingIcon {
            // Show the activity indicator and loading view
            activityIndicator.isHidden = false
            Loading.isHidden = false
            // Start animating the activity indicator
            activityIndicator.startAnimating()
        }
    }

    func hideLoading() {
        // Check if the loading icon should be shown based on the setting
        if SettingsManager.shared.shouldShowLoadingIcon {
            // Stop animating the activity indicator
            activityIndicator.stopAnimating()
            // Hide the loading view and activity indicator
            Loading.isHidden = true
            activityIndicator.isHidden = true
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Called when the web view begins to load a provisional navigation
        showLoading()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Called when the web view finishes loading a navigation

        // Hide the loading indicator
        hideLoading()
    }

 
    @objc func mymethodforref(refresh:UIRefreshControl){
        if SettingsManager.shared.pullToRefreshEnabled {
        webView.reload()
        refController.endRefreshing()
        }
    }
    
    func setupAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            let alert = UIAlertController(title: "", message: SettingsManager.shared.inAppPurchasesFailedMessage, preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: SettingsManager.shared.paymentSuccesButtonText, style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func setupSuccesAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            let alert = UIAlertController(title: "", message: SettingsManager.shared.setSuccessMessage, preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: SettingsManager.shared.paymentSuccesButtonText, style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        })
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView {
            decisionHandler(.allow)
            return
        }
        
        let url = navigationAction.request.url!
        let app = UIApplication.shared
        
        // Handle target="_blank"
        if navigationAction.targetFrame == nil {
            if app.canOpenURL(url) {
                decisionHandler(.allow)
                return
            }
        }
        
        if url.scheme == "tel" || url.scheme == "mailto" {
            if app.canOpenURL(url) {
                app.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        
        if url.scheme == "viber" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        if url.scheme == "fb-messenger" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        guard let host = url.host else {
            hideLoading()
            decisionHandler(.allow)
            return
        }
        
        if SettingsManager.shared.allowDomains.contains(host) {
            hideLoading()
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
            return
        }
        
        if SettingsManager.shared.openExtranalUrlInBrowser {
            if !SettingsManager.websiteUrl.contains(host) {
                hideLoading()
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
                return
            }
        }
        
        let urlString = url.absoluteString;
        if urlString.contains("screenshot") {
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.captureScreenShot()
            })
        }
        
        if urlString.contains("preventsleeping") {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        if urlString.contains("scanningmode") {
            UIScreen.main.brightness = CGFloat(1)
        }
        
        if urlString.contains("reset") {
            clearCache()
        }
        
        if urlString.contains("spinneron") {
            showLoading()
        }
        if urlString.contains("spinneroff") {
            hideLoading()
        }
        
        
        var paramsMap = [String: String]()
        if urlString.contains("shareurl") || urlString.contains("expiryurl") || urlString.contains("tracking") ||
            (urlString.contains("productid") && urlString.contains("successurl")) {
            if let components = URLComponents(string: url.absoluteString), let items = components.queryItems {
                paramsMap = items.reduce(into: [String: String]()) { (result, item) in
                    result[item.name] = item.value ?? ""
                }
            }
        }
        productID = paramsMap
        
        if paramsMap["expiryurl"] != nil {
            SettingsManager.shared.expiryUrl = paramsMap["expiryurl"]!
        }

        if paramsMap["tracking"] != nil {
            
            print(paramsMap, "🍎paramsMap" )
            let noUrl = paramsMap["nourl"] ?? ""
            let yesUrl = paramsMap["yesurl"] ?? ""
//            if SettingsManager.shared.allowDomains.contains(yesUrl) {
//                SettingsManager.shared.isExternalUrl = false
//            } else {
//                SettingsManager.shared.isExternalUrl = true
//            }
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                        case .authorized:
                            print("enable tracking")
                        let urlRequest = URLRequest(url: URL(string: yesUrl)!)
                        DispatchQueue.main.async {
                            if paramsMap["tracking"] == "true" {
                                webView.load(urlRequest)
                            }
                        }
                        case .denied:
                            print("disable tracking")
                        let urlRequest = URLRequest(url: URL(string: noUrl)!)
                        DispatchQueue.main.async {
                            if paramsMap["tracking"] == "true" {
                                webView.load(urlRequest)
                            }
                        }
                        default:
                            print("disable tracking")
                        let urlRequest = URLRequest(url: URL(string: noUrl)!)
                        DispatchQueue.main.async {
                            if paramsMap["tracking"] == "true" {
                                webView.load(urlRequest)
                            }
                        }
                    }
                }
            }
        }

        if paramsMap["productid"] != nil && paramsMap["successurl"] != nil {
            // call in app purchases
            showLoading()
            let productID = paramsMap["productid"]!
            IAPManager.shared.purchase(purchase: productID) { res in
                self.hideLoading()
                if let res = res {
                    if res {
                        let url = paramsMap["successurl"] ?? ""
                        UserDefaults.standard.setValue(true, forKey: "isSubsribed")
                        let urlRequest = URLRequest(url: URL(string: url)!)
//                        setupSuccesAlert()
                        webView.load(urlRequest)
                    } else {
                        self.setupAlert()
                    }
                } else {
                    self.setupAlert()
                }
                
            } failure: { error in
                self.hideLoading()
                print(error, "error🍎")
                self.setupAlert()
            }
            
            decisionHandler(.cancel)
            return
        }
        
        if (paramsMap["shareurl"] != nil) {
            if let shareUrl = URL(string: String(paramsMap["shareurl"]!)) {
                callShare(shareUrl: shareUrl)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // Disable the pinch gesture recognizer for zooming
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Check if the target frame is the main frame
        if let frame = navigationAction.targetFrame, frame.isMainFrame {
            // If the target frame is the main frame, return nil (do not create a new web view)
            return nil
        }
        // For "_blank" target or non-mainFrame target
        // Load the requested URL in the current web view
        webView.load(navigationAction.request)
        // Return nil to indicate that a new web view is not created
        return nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        if productID["productid"] != nil {
            //show alert
            let attributedTitle = NSAttributedString(string: SettingsManager.shared.internetErrorTitle, attributes: [
                NSAttributedString.Key.foregroundColor : SettingsManager.shared.textColour
            ])
            let attributedMessage = NSAttributedString(string: SettingsManager.shared.internetErrorMessage, attributes: [
                NSAttributedString.Key.foregroundColor : SettingsManager.shared.textColour
            ])
            let alertController = UIAlertController(title: SettingsManager.shared.internetErrorTitle, message: SettingsManager.shared.internetErrorMessage, preferredStyle: .alert)
            alertController.setValue(attributedTitle, forKey: "attributedTitle")
            alertController.setValue(attributedMessage, forKey: "attributedMessage")
            
            let exitAction = UIAlertAction(title: SettingsManager.shared.internetErrorExitButtonText, style: .default) { action in
                exit(0);
            }
            exitAction.setValue(SettingsManager.shared.textColour, forKey: "titleTextColor")
            
            let retryAction = UIAlertAction(title: SettingsManager.shared.internetErrorRetryButtonText, style: .default) { action in
                webView.reload()
            }
            retryAction.setValue(SettingsManager.shared.textColour, forKey: "titleTextColor")
            
            //add actions to alert
            alertController.addAction(exitAction)
            alertController.addAction(retryAction)
            self.present(alertController, animated: true)
        }
    }
}


extension ViewController2: WKDownloadHelperDelegate {
    func canNavigate(toUrl: URL) -> Bool {
        true
    }
    
    func didFailDownloadingFile(error: Error) {
        print("error while downloading file \(error)")
    }
    
    func didDownloadFile(atUrl: URL) {
        // Print a message indicating that the file was downloaded
        print("Did download file!")
        // Perform UI-related tasks on the main thread
        DispatchQueue.main.async {
            // Create an activity view controller with the downloaded file URL
            let activityVC = UIActivityViewController(activityItems: [atUrl], applicationActivities: nil)
            // Configure the popover presentation controller for iPad or large screens
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = self.view.frame
            // If you have a bar button item to anchor the popover, set it here
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            // Present the activity view controller
            self.present(activityVC, animated: true, completion: nil)
        }
    }

}


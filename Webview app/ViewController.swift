import UIKit

class ViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
//        let storyBoard: UIStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
//        let vc = storyBoard.instantiateViewController(withIdentifier: "launchViewController")
//        vc.view.backgroundColor = SettingsManager.shared.splashBackgroundColour
//        self.view.addSubview(vc.view)
//        self.addChild(vc)
//        vc.didMove(toParent: self)
        
        self.view.backgroundColor = SettingsManager.shared.splashBackgroundColour
    }
    
    func startProcess() {
        // check and request authorization
        SettingsManager.shared.requestUdid() {
            SettingsManager.shared.checkPushAuthorizationWith(self) {
                DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                    _ = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.fire), userInfo: nil, repeats: false)
                })
            }
        }
    }
        
    @objc func fire() {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let balanceViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController2") as! ViewController2
            balanceViewController.urlstring = SettingsManager.websiteUrl
            self.present(balanceViewController, animated: true, completion: nil)
            
            balanceViewController.view.backgroundColor = SettingsManager.shared.themeColour
            balanceViewController.webView.backgroundColor = .white
            balanceViewController.webView.isOpaque = false
            
            if SettingsManager.shared.launchCount == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                    let attributedString = NSAttributedString(string: SettingsManager.shared.firstLaunchMessage, attributes: [
                        NSAttributedString.Key.foregroundColor : SettingsManager.shared.textColour
                    ])
                    let alertController = UIAlertController(title: nil, message: SettingsManager.shared.firstLaunchMessage, preferredStyle:.alert)
                    alertController.setValue(attributedString, forKey: "attributedMessage")
                    
                    let action = UIAlertAction(title: SettingsManager.shared.firstLaunchButtonText, style: .default, handler:nil)
                    action.setValue(SettingsManager.shared.textColour, forKey: "titleTextColor")
                    
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                })
            }
        })
    }
}


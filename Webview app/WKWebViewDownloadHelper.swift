

import Foundation
import WebKit

struct MimeType {
    var type:String
    var fileExtension:String
}

protocol WKWebViewDownloadHelperDelegate {
    func fileDownloadedAtURL(url:URL)
}

class WKWebviewDownloadHelper:NSObject {
    
    var webView:WKWebView
    var mimeTypes:[MimeType]
    var delegate:WKWebViewDownloadHelperDelegate
    
    // Initialization
    init(webView:WKWebView, mimeTypes:[MimeType], delegate:WKWebViewDownloadHelperDelegate) {
        self.webView = webView
        self.mimeTypes = mimeTypes
        self.delegate = delegate
        super.init()
        webView.navigationDelegate = self
    }
    
    private var fileDestinationURL: URL?
    
    private func downloadData(fromURL url: URL, fileName: String, completion: @escaping (Bool, URL?) -> Void) {
        // Get cookies from the WKWebView's httpCookieStore
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { cookies in
            let session = URLSession.shared
            // Set cookies for the session
            session.configuration.httpCookieStorage?.setCookies(cookies, for: url, mainDocumentURL: nil)
            // Create a download task
            let task = session.downloadTask(with: url) { localURL, urlResponse, error in
                if let localURL = localURL {
                    // Move the downloaded file to a destination and get the destination URL
                    let destinationURL = self.moveDownloadedFile(url: localURL, fileName: fileName)
                    completion(true, destinationURL)
                } else {
                    // Call completion with failure status and nil destination URL
                    completion(false, nil)
                }
            }
            // Resume the download task
            task.resume()
        }
    }

    private func getDefaultFileName(forMimeType mimeType: String) -> String {
        // Iterate through each record in the mimeTypes array
        for record in self.mimeTypes {
            // Check if the provided mimeType contains the current record's type
            if mimeType.contains(record.type) {
                // If there is a match, return a default file name with the record's file extension
                return "default." + record.fileExtension
            }
        }
        
        // If no match is found, return a default file name without an extension
        return "default"
    }

    
    private func getFileNameFromResponse(_ response: URLResponse) -> String? {
        if let httpResponse = response as? HTTPURLResponse {
            // Extract all header fields from the HTTP response
            let headers = httpResponse.allHeaderFields
            
            // Check if the "Content-Disposition" header is present
            if let disposition = headers["Content-Disposition"] as? String {
                // Split the "Content-Disposition" value into components using space as the separator
                let components = disposition.components(separatedBy: " ")
                
                // Check if there are more than one component
                if components.count > 1 {
                    // Extract the second component and split it using "=" as the separator
                    let innerComponents = components[1].components(separatedBy: "=")
                    
                    // Check if there are more than one inner component
                    if innerComponents.count > 1 {
                        // Check if the first inner component contains "filename"
                        if innerComponents[0].contains("filename") {
                            // Return the extracted file name
                            return innerComponents[1]
                        }
                    }
                }
            }
        }
        
        // Return nil if no file name is found in the response
        return nil
    }
    
    private func isMimeTypeConfigured(_ mimeType: String) -> Bool {
        // Iterate through each record in the mimeTypes array
        for record in self.mimeTypes {
            // Check if the provided mimeType contains the current record's type
            if mimeType.contains(record.type) {
                // If there is a match, return true
                return true
            }
        }
        
        // If no match is found, return false
        return false
    }

    private func moveDownloadedFile(url: URL, fileName: String) -> URL {
        // Get the temporary directory path
        let tempDir = NSTemporaryDirectory()
        
        // Create the destination path by appending the filename to the temporary directory path
        let destinationPath = tempDir + fileName
        
        // Create the destination URL using the destination path
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        // Remove any existing file at the destination URL
        try? FileManager.default.removeItem(at: destinationURL)
        
        // Move the downloaded file from its current location to the destination URL
        try? FileManager.default.moveItem(at: url, to: destinationURL)
        
        // Return the destination URL
        return destinationURL
    }

}


extension WKWebviewDownloadHelper: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow the navigation action
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Check if the response contains a valid MIME type
        if let mimeType = navigationResponse.response.mimeType {
            // Check if the MIME type is configured for download
            if isMimeTypeConfigured(mimeType) {
                // Check if the response contains a valid URL
                if let url = navigationResponse.response.url {
                    if #available(iOS 14.5, *) {
                        // If running on iOS 14.5 or later, allow the download directly
                        decisionHandler(.download)
                    } else {
                        // For iOS versions earlier than 14.5, manually handle the download
                        var fileName = getDefaultFileName(forMimeType: mimeType)
                        if let name = getFileNameFromResponse(navigationResponse.response) {
                            fileName = name
                        }
                        // Initiate the download and handle the completion
                        downloadData(fromURL: url, fileName: fileName) { success, destinationURL in
                            if success, let destinationURL = destinationURL {
                                // Notify the delegate that the file has been downloaded
                                self.delegate.fileDownloadedAtURL(url: destinationURL)
                            }
                        }
                        // Cancel the navigation response as it will be manually handled
                        decisionHandler(.cancel)
                    }
                    return
                }
            }
        }
        // Allow the navigation response by default
        decisionHandler(.allow)
    }
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        // This function is called when a download is initiated in response to a navigation request
        print(" navigationresponse didbecome download ")
        
        // Set the delegate for the download to handle further events
        download.delegate = self
    }

}

@available(iOS 15.0, *)
extension WKWebviewDownloadHelper: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        // Get the temporary directory path
        let temporaryDir = NSTemporaryDirectory()
        
        // Construct the destination file URL by appending the suggested filename to the temporary directory
        let fileName = temporaryDir + "/" + suggestedFilename
        let url = URL(fileURLWithPath: fileName)
        
        // Store the destination URL for future reference
        fileDestinationURL = url
        
        // Call the completion handler with the constructed URL
        completionHandler(url)
    }

    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("download failed \(error)")
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        // Print a message indicating that the download has finished
        print("Download finished")
        
        // Check if the file destination URL is available
        if let url = fileDestinationURL {
            // Notify the delegate that the file has been downloaded by passing the file URL
            self.delegate.fileDownloadedAtURL(url: url)
        }
    }

}

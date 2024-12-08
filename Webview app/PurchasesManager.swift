
import StoreKit

class PurchasesManager: NSObject {
    static let shared = PurchasesManager()
    
    private var productId: String?
    private var resultCompletion: ((_ result: Bool, _ message: String, _ receipt: String?) -> Void)?
    
    // request product info from Apple
    func sendPayquest(productId: String, completion: @escaping ((_ result: Bool, _ message: String, _ receipt: String?) -> Void)) {
        SKPaymentQueue.default().remove(self)
        SKPaymentQueue.default().add(self)
        if SKPaymentQueue.canMakePayments() == true {
            self.productId = productId
            self.resultCompletion = completion
            
            let set: Set = [productId]
            let request = SKProductsRequest.init(productIdentifiers: set)
            request.delegate = self
            request.start()
        }
    }
    
    func verifyPurchaseWithPaymentTransaction(resultState: Int, completion: ((_ result: Bool) -> Void)) {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return }
        
        SKPaymentQueue.default().remove(self)
        let receiptData = Data.ReferenceType(contentsOf: receiptUrl)
        if receiptData != nil {
            guard let encodeStr = receiptData?.base64EncodedString(options: .endLineWithLineFeed) else {
                if resultCompletion != nil {
                    resultCompletion!(false, "payment can't get receipt from Apple", nil)
                    resultCompletion = nil
                }
                completion(false)
                return;
            }
            
            if resultCompletion != nil {
                resultCompletion!(true, "payment get receipt from Apple", encodeStr)
                resultCompletion = nil
            }
            completion(true)
        }
        else{
            productId = nil
            
            // deal error, like show error toast
            if resultCompletion != nil {
                resultCompletion!(false, "payment can't get receipt from Apple", nil)
                resultCompletion = nil
            }
            completion(false)
        }
    }
    
    func isReceiptValidation(completion: @escaping ((_ isExistSubscribe: Bool, _ isValid: Bool) -> Void)) {
        let receiptPath = Bundle.main.appStoreReceiptURL?.path
        if !FileManager.default.fileExists(atPath: receiptPath!) {
            completion(false, false)
            return
        }
        
        var receiptData: NSData?
        do {
            receiptData = try NSData(contentsOf: Bundle.main.appStoreReceiptURL!, options: NSData.ReadingOptions.alwaysMapped)
        }
        catch {
            print("ERROR: " + error.localizedDescription)
            completion(false, false)
            return
        }
        let base64encodedReceipt = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        let requestDictionary = ["receipt-data": base64encodedReceipt!,
                                 "password": "your iTunes Connect shared secret"]
        
        guard JSONSerialization.isValidJSONObject(requestDictionary) else {
            print("requestDictionary is not valid JSON")
            completion(false, false)
            return
        }
        
        do {
            // this works but as noted above it's best to use your own trusted server
            let requestData = try JSONSerialization.data(withJSONObject: requestDictionary)
            let validationURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
            guard let validationURL = URL(string: validationURLString) else {
                print("the validation url could not be created, unlikely error")
                completion(false, false)
                return
            }
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            var request = URLRequest(url: validationURL)
            request.httpMethod = "POST"
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
            let task = session.uploadTask(with: request, from: requestData) { (data, response, error) in
                if let data = data, error == nil {
                    do {
                        var isValid = false
                        
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
                        if json != nil {
                            print("success. here is the json representation of the app receipt: \(String(describing: json))")
                            
                            let cancelDateMS = json?["cancellation_date_ms"]
                            let expiresDateMS = json?["expires_date_ms"]
                            let currentDateMS = Date().timeIntervalSince1970
                            
                            if cancelDateMS != nil, let cancelMS = Double(cancelDateMS!) {
                                isValid = cancelMS>=currentDateMS
                            }
                            
                            if !isValid, expiresDateMS != nil, let expiresMS = Double(expiresDateMS!) {
                                isValid = expiresMS>=currentDateMS
                            }
                        }
                        
                        completion(true, isValid)
                    }
                    catch let error as NSError {
                        print("json serialization failed with error: \(error)")
                        completion(true, false)
                    }
                }
                else {
                    if error != nil {
                        print("the upload task returned an error: \(String(describing: error))")
                    }
                    completion(true, false)
                }
            }
            task.resume()
        }
        catch let error as NSError {
            print("json serialization failed with error: \(error)")
            completion(false, false)
        }
    }
}

extension PurchasesManager : SKProductsRequestDelegate {
    // check product info from Apple
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("received product response")
        let products = response.products
        if products.count == 0 {
            productId = nil
            if resultCompletion != nil {
                resultCompletion!(false, "can't find product from Apple", nil)
                resultCompletion = nil
            }
            return
        }
        
        var target: SKProduct? = nil
        products.forEach { item in
            if item.productIdentifier == self.productId {
                target = item
            }
        }
        
        if target == nil {
            productId = nil
            if resultCompletion != nil {
                resultCompletion!(false, "can't find target product from Apple", nil)
                resultCompletion = nil
            }
            return;
        }
        
        // start Apple payment
        let payment = SKPayment(product: target!)
        SKPaymentQueue.default().add(payment)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request failed")
        productId = nil
        if resultCompletion != nil {
            resultCompletion!(false, "request Apple failed", nil)
            resultCompletion = nil
        }
        SKPaymentQueue.default().remove(self)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("request finished")
    }
}

extension PurchasesManager : SKPaymentTransactionObserver {
    // get Apple paytment result
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { tran in
            switch tran.transactionState {
            case .purchased:
                // Apple payment succeed
                // App server need verify receipt
                self.verifyPurchaseWithPaymentTransaction(resultState: tran.transactionState.rawValue) { result in
                    if result {
                        SKPaymentQueue.default().finishTransaction(tran)
                    }
                    
                    productId = nil
                    resultCompletion = nil
                }
                break
            case .purchasing:
                break
            case .failed, .deferred:
                SKPaymentQueue.default().finishTransaction(tran)
                productId = nil
                if resultCompletion != nil {
                    resultCompletion!(false, "purchase failed!", nil)
                    resultCompletion = nil
                }
                SKPaymentQueue.default().remove(self)
                break
            case .restored:
                SKPaymentQueue.default().finishTransaction(tran)
                break
            default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("transactions finished")
    }
}

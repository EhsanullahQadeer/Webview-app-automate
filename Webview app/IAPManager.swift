
import Foundation
import SwiftyStoreKit
import StoreKit

class IAPManager: NSObject {
    static let shared = IAPManager()
    typealias ProductIdentifier = String
    
    // MARK: - Variables
    
    func purchase(purchase: ProductIdentifier, completion: @escaping (Bool?) -> Void, failure: @escaping escapeNetworkError) {
        SwiftyStoreKit.purchaseProduct(purchase, completion: { result in
            switch result {
            case .success(let product):
                completion(true)
                break
            case .error(let err):
                var errText = "Error"
                if err.errorCode == 2 {
                    errText = "The operation couldn’t be completed."
                } else {
                    errText = err.localizedDescription
                }
                print("purchase(purchase: err", errText)
                failure(NetworkError(.other(errText)))
            case .deferred(purchase: let purchase):
                print(purchase, "purchase")
            }
        })
    }
    
    func compleateTransations() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored, .purchasing:
                    print("SwiftyStoreKit.completeTransactions purchased, .restored")
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content
                case .failed, .deferred:
                    print("SwiftyStoreKit.completeTransactions failed, .purchasing, .deferred")
                    break // do nothing
                @unknown default:
                    print("SwiftyStoreKit.completeTransactions @unknown")
                    break // do nothing
                }
            }
        }
    }
    
    func setupStorekit(complation: @escaping (String?) -> Void) {
        let appleValidator = AppleReceiptValidator(service: .production)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                
                let pendingRenewalInfos = receipt["pending_renewal_info"] as? NSArray
                let latestInfo = pendingRenewalInfos?.firstObject as? NSDictionary
                if let autoRenewStatus = latestInfo?["auto_renew_status"] as? String {
                    complation(autoRenewStatus)
                } else {
                    fatalError("Couldn‘t determine expiration intent")
                }
                let model = parse(receipt, type: inAppPurchase.self)
                let in_app = model?.receipt?.in_app ?? []
                let sortReceipt = in_app.sorted(by: { ($0.expires_date_ms ?? "") < ($1.expires_date_ms ?? "") })
                let dateMS = Int64(sortReceipt.last?.expires_date_ms ?? "0")!
                if dateMS >= Date().timestamp {
                    print("inAppPurchase is not expire ")
                } else {
                    print("inAppPurchase is expire")
                }
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }

}
    


typealias escapeNetworkError = (NetworkError?) -> Void

enum NetworkErrorType {
    case server
    case decoding
    case other(String)
}

struct NetworkError: Error {
    let type: NetworkErrorType
    let code: Int?
    let status: Int?
    let message: String?
}

extension NetworkError {
    init(_ type: NetworkErrorType, code: Int? = nil, status: Int? = nil) {
        self.type = type
        self.code = code
        self.status = status
        
        switch type {
            case .server: message = "Server error: \(code ?? 0)"
            case .decoding: message = "Decoding error"
            case .other(let text): message = "\(text)"
        }
    }
}

import Foundation

func parse<T: Decodable>(_ json: [String: Any]?, type: T.Type) -> T? {
    guard let data = json?.inData, let model = try? JSONDecoder().decode(type.self, from: data) else { return nil }
    return model
}

extension [String:Any] {
    
    var inData: Data? {
        return try? JSONSerialization.data(withJSONObject: self)
    }
    
}
extension Date {
    
    var timestamp:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

struct inAppPurchase: Codable {
    
    var status: Bool?
    var receipt: Receipt?
    var environment: String?
    var latest_receipt: String?
    var latest_receipt_info: [ReceiptInfo]?
    var pending_renewal_info: [PendingRenewalInfo]?
    
    
    init(from decoder: Decoder) {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        status = try? values?.decodeIfPresent(Bool.self, forKey: .status)
        receipt = try? values?.decodeIfPresent(Receipt.self, forKey: .receipt)
        environment = try? values?.decodeIfPresent(String.self, forKey: .environment)
        latest_receipt = try? values?.decodeIfPresent(String.self, forKey: .latest_receipt)
        latest_receipt_info = try? values?.decodeIfPresent([ReceiptInfo].self, forKey: .latest_receipt_info)
        pending_renewal_info = try? values?.decodeIfPresent([PendingRenewalInfo].self, forKey: .pending_renewal_info)
    }
}


struct ReceiptInfo: Codable {
    
    var quantity: String?
    var product_id: String?
    var expires_date: String?
    var expires_date_ms: String?
    var purchase_date: String?
    var purchase_date_ms: String?
    var is_trial_period: String?
    var transaction_id: String?
    var expires_date_pst: String?
    var purchase_date_pst: String?
    var original_transaction_id: String?
    var in_app_ownership_type: String?
    var is_in_intro_offer_period: String?
    var original_purchase_date: String?
    var web_order_line_item_id: String?
    var original_purchase_date_ms: String?
    var original_purchase_date_pst: String?
    var subscription_group_identifier: String?
    
    init(from decoder: Decoder) {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        quantity = try? values?.decodeIfPresent(String.self, forKey: .quantity)
        product_id = try? values?.decodeIfPresent(String.self, forKey: .product_id)
        expires_date = try? values?.decodeIfPresent(String.self, forKey: .expires_date)
        expires_date_ms = try? values?.decodeIfPresent(String.self, forKey: .expires_date_ms)
        purchase_date = try? values?.decodeIfPresent(String.self, forKey: .purchase_date)
        purchase_date_ms = try? values?.decodeIfPresent(String.self, forKey: .purchase_date_ms)
        is_trial_period = try? values?.decodeIfPresent(String.self, forKey: .is_trial_period)
        transaction_id = try? values?.decodeIfPresent(String.self, forKey: .transaction_id)
        expires_date_pst = try? values?.decodeIfPresent(String.self, forKey: .expires_date_pst)
        purchase_date_pst = try? values?.decodeIfPresent(String.self, forKey: .purchase_date_pst)
        original_transaction_id = try? values?.decodeIfPresent(String.self, forKey: .original_transaction_id)
        in_app_ownership_type = try? values?.decodeIfPresent(String.self, forKey: .in_app_ownership_type)
        is_in_intro_offer_period = try? values?.decodeIfPresent(String.self, forKey: .is_in_intro_offer_period)
        original_purchase_date = try? values?.decodeIfPresent(String.self, forKey: .original_purchase_date)
        web_order_line_item_id = try? values?.decodeIfPresent(String.self, forKey: .web_order_line_item_id)
        original_purchase_date_ms = try? values?.decodeIfPresent(String.self, forKey: .original_purchase_date_ms)
        original_purchase_date_pst = try? values?.decodeIfPresent(String.self, forKey: .original_purchase_date_pst)
        subscription_group_identifier = try? values?.decodeIfPresent(String.self, forKey: .subscription_group_identifier)
        
    }
   
}
    
struct PendingRenewalInfo: Codable {
    
    var product_id: String?
    var auto_renew_status: String?
    var expiration_intent: String?
    var original_transaction_id: String?
    var auto_renew_product_id: String?
    var is_in_billing_retry_period: String?
    
    init(from decoder: Decoder) {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        product_id = try? values?.decodeIfPresent(String.self, forKey: .product_id)
        auto_renew_status = try? values?.decodeIfPresent(String.self, forKey: .auto_renew_status)
        expiration_intent = try? values?.decodeIfPresent(String.self, forKey: .expiration_intent)
        original_transaction_id = try? values?.decodeIfPresent(String.self, forKey: .original_transaction_id)
        auto_renew_product_id = try? values?.decodeIfPresent(String.self, forKey: .auto_renew_product_id)
        is_in_billing_retry_period = try? values?.decodeIfPresent(String.self, forKey: .is_in_billing_retry_period)
    }
    
}

struct Receipt: Codable {

    var adam_id: Int?
    var download_id: Int?
    var app_item_id: Int?
    var bundle_id: String?
    var receipt_type: String?
    var request_date: String?
    var request_date_ms: Int?
    var in_app: [ReceiptInfo]?
    var application_version: Int?
    var request_date_pst: String?
    var receipt_creation_date: String?
    var receipt_creation_date_ms: Int?
    var original_purchase_date: String?
    var original_purchase_date_ms: Int?
    var version_external_identifier: Int?
    var original_purchase_date_pst: String?
    var receipt_creation_date_pst: String?
    var original_application_version: String?
    
    init(from decoder: Decoder) {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        adam_id = try? values?.decodeIfPresent(Int.self, forKey: .adam_id)
        download_id = try? values?.decodeIfPresent(Int.self, forKey: .download_id)
        app_item_id = try? values?.decodeIfPresent(Int.self, forKey: .app_item_id)
        bundle_id = try? values?.decodeIfPresent(String.self, forKey: .bundle_id)
        receipt_type = try? values?.decodeIfPresent(String.self, forKey: .receipt_type)
        request_date = try? values?.decodeIfPresent(String.self, forKey: .request_date)
        request_date_ms = try? values?.decodeIfPresent(Int.self, forKey: .request_date_ms)
        in_app = try? values?.decodeIfPresent([ReceiptInfo].self, forKey: .in_app)
        application_version = try? values?.decodeIfPresent(Int.self, forKey: .application_version)
        request_date_pst = try? values?.decodeIfPresent(String.self, forKey: .request_date_pst)
        receipt_creation_date = try? values?.decodeIfPresent(String.self, forKey: .receipt_creation_date)
        receipt_creation_date_ms = try? values?.decodeIfPresent(Int.self, forKey: .receipt_creation_date_ms)
        original_purchase_date = try? values?.decodeIfPresent(String.self, forKey: .original_purchase_date)
        original_purchase_date_ms = try? values?.decodeIfPresent(Int.self, forKey: .original_purchase_date_ms)
        version_external_identifier = try? values?.decodeIfPresent(Int.self, forKey: .version_external_identifier)
        original_purchase_date_pst = try? values?.decodeIfPresent(String.self, forKey: .original_purchase_date_pst)
        receipt_creation_date_pst = try? values?.decodeIfPresent(String.self, forKey: .receipt_creation_date_pst)
        original_application_version = try? values?.decodeIfPresent(String.self, forKey: .original_application_version)
    }

}
    
enum CodingKeys: String, CodingKey {
    case status
    case receipt
    case environment
    case latest_receipt
    case latest_receipt_info
    case pending_renewal_info
    case quantity
    case expires_date
    case expires_date_ms
    case purchase_date
    case purchase_date_ms
    case is_trial_period
    case transaction_id
    case expires_date_pst
    case purchase_date_pst
    case original_transaction_id
    case in_app_ownership_type
    case is_in_intro_offer_period
    case original_purchase_date
    case web_order_line_item_id
    case original_purchase_date_ms
    case original_purchase_date_pst
    case subscription_group_identifier
    case product_id
    case auto_renew_status
    case expiration_intent
    case auto_renew_product_id
    case is_in_billing_retry_period
    case adam_id
    case download_id
    case app_item_id
    case bundle_id
    case receipt_type
    case request_date
    case request_date_ms
    case in_app
    case application_version
    case request_date_pst
    case receipt_creation_date
    case receipt_creation_date_ms
    case version_external_identifier
    case receipt_creation_date_pst
    case original_application_version
}



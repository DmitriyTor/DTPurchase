//
//  IAPWrapper.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation
import StoreKit

public final class DTIAPWrapper: NSObject {
    
    //Properties
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    fileprivate var productIds = [String]()
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var fetchProductCompletion: (([DTIAPProduct], DTPurchaseStatus)->Void)?
    
    fileprivate var productToPurchase: DTIAPProduct?
    fileprivate var purchaseProductCompletion: ((DTPurchaseStatus, DTIAPProduct?, SKPaymentTransaction?)->Void)?
    fileprivate var receiptCompletion: ((_ receipt: String) -> Void)?
    
    private var products = [SKProduct]()
    
    // Set Product Ids
    func setProductIds(ids: [String]) {
        self.productIds = ids
    }
    
    // fetch avaliable products
    func fetchAvailableProducts(complition: @escaping (([DTIAPProduct], DTPurchaseStatus)->Void)) {
        
        self.fetchProductCompletion = complition
        if self.productIds.isEmpty {
            let status = DTPurchaseStatus(status: .setProductIds, detailError: "Product id is empty")
            complition([], status)
        }
        else {
            productsRequest = SKProductsRequest(productIdentifiers: Set(self.productIds))
            productsRequest.delegate = self
            productsRequest.start()
        }
    }
    
    // purchase product
    func purchase(product: DTIAPProduct, completion: @escaping ((DTPurchaseStatus, DTIAPProduct?, SKPaymentTransaction?) -> Void)) {
        
        self.purchaseProductCompletion = completion
        self.productToPurchase = product
        
        if self.canMakePurchases() {
            guard let _product = self.products.filter({ $0.productIdentifier == product.productIdentifier}).first else {
                let status = DTPurchaseStatus(status: .disabled, detailError: nil)
                completion(status, nil, nil)
                return
            }
            let payment = SKPayment(product: _product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            NSLog("Product to purchase: \(product.productIdentifier)")
            productID = product.productIdentifier
        } else {
            let status = DTPurchaseStatus(status: .disabled, detailError: "Method SKPaymentQueue.canMakePayments return false")
            completion(status, nil, nil)
        }
    }
    
    // restore purchase
    func restorePurchase(completion: @escaping ((DTPurchaseStatus, DTIAPProduct?, SKPaymentTransaction?) -> Void)){
        self.purchaseProductCompletion = completion
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func getReceipt(isNeedToUpdate: Bool, completion: @escaping (_ receipt: String) -> Void) {
        self.receiptCompletion = completion
        self.prepareReceipt(isNeedToUpdate: isNeedToUpdate)
    }
    
    /// get receipt for send to server
    /// - Parameter isFromServer: загрузить с сервера или локальные
    private func prepareReceipt(isNeedToUpdate: Bool) {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path), !isNeedToUpdate {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)
                let receipt = receiptData.base64EncodedString(options: [])
                self.receiptCompletion?(receipt)
                self.receiptCompletion = nil
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        } else {
            updateReceipt()
        }
    }
    
    // get new receipt from Apple server for send to server
    func updateReceipt() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
    }
}

//MARK: - SKProductsRequestDelegate, SKPaymentTransactionObserver
extension DTIAPWrapper: SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    
    // Request receipt success
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func requestDidFinish(_ request: SKRequest) {
        self.prepareReceipt(isNeedToUpdate: false)
    }
    
    // Request receipt failed
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        
    }
    
    // Request products
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if response.products.count > 0, let completion = self.fetchProductCompletion {
            let status = DTPurchaseStatus(status: .fetched, detailError: nil)
            completion(response.products.map { DTIAPProduct(product: $0) }, status)
            self.products = response.products
        } else {
            if let completion = self.fetchProductCompletion {
                let status = DTPurchaseStatus(status: .failedFetch, detailError: "Cant fetch products or returned empty list")
                
                completion([], status)
            }
        }
    }
    
    // restore product
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if let completion = self.purchaseProductCompletion {
            let status = DTPurchaseStatus(status: .successRestored, detailError: nil)
            completion(status, nil, nil)
        }
    }
    
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let completion = self.purchaseProductCompletion {
            let status = DTPurchaseStatus(status: .failedRestore, detailError: error.localizedDescription)
            completion(status, nil, nil)
        }
    }
    
    // IAP payment queue
    @available(*, deprecated, message: "Не использовать метод. Необходим для протокола StoreKit")
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction:AnyObject in transactions {
        if let trans = transaction as? SKPaymentTransaction {
            switch trans.transactionState {
            case .purchased:
                
                SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                if let completion = self.purchaseProductCompletion {
                    let status = DTPurchaseStatus(status: .purchased, detailError: trans.error?.localizedDescription)
                    completion(status, self.productToPurchase, trans)
                }
                break
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                if let completion = self.purchaseProductCompletion {
                    let status = DTPurchaseStatus(status: .failedBuy, detailError: trans.error?.localizedDescription)
                    completion(status, nil, nil)
                }
                break
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                break
                
            default: break
            }}}
    }
    
}

extension SKProduct {

    var localizedPrice: String {
        if self.price == 0.00 {
            return "Free"
        } else {
            let formatter = NumberFormatter().currencyFormatter()
            formatter.locale = self.priceLocale

            guard let formattedPrice = formatter.string(from: self.price) else {
                return "N/A"
            }

            return formattedPrice
        }
    }
}


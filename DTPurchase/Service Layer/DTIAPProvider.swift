//
//  IAPProvider.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import UIKit

public final class DTIAPProvider {
    
    private let defaults = UserDefaults.standard
    private let iAPWrapper = DTIAPWrapper()

    /// Delegate for extension your purchase class (f.e. can return receipt)
    public weak var delegate: DTPurchaseDelegate?
    
    /// If true - receipt get from Apple Server and then returned in DTPurchaseReturn(receipt...) func
    public var receiptAlwaysFromServer = false
    
    public init() {
        self.setProductIds()
    }
    
    private func setProductIds() {
        guard let ids = UIApplication.productIDs else {
            fatalError("Set array of ids in Info.plist by key DTPurchase!")
        }
        self.iAPWrapper.setProductIds(ids: ids)
        self.fetchProducts(completion: nil)
    }
    
    private var availableProduct = [DTIAPProduct]()
    
    /// Достаем продукты с сервака эппл
    private func fetchProducts(completion: (([DTIAPProduct]) -> Void)?) {
        self.iAPWrapper.fetchAvailableProducts { (products, status) in
            if status != .fetched {
                self.getProductsFromUserDefaults()
            } else {
                self.availableProduct = products
                completion?(self.availableProduct)
                self.save2UserDefaults()
                self.iAPWrapper.getReceipt(isNeedToUpdate: self.receiptAlwaysFromServer) { (receipt) in
                    self.delegate?.DTPurchaseReturn(receipt: receipt, after: .fetch)
                }
            }
        }
    }
}

extension DTIAPProvider {
    
    /// List of available products
    public func getAvailableItem(completion: @escaping([DTIAPProduct]) -> Void) {
        if self.availableProduct.count > 0 {
            completion(self.availableProduct)
        } else {
            self.fetchProducts(completion: completion)
        }
        
    }
    
    /// Method for bought product
    /// - Parameter product: product
    /// - Parameter completion: callback block
    public func purchaseProduct(product: DTIAPProduct, completion: @escaping (DTPurchaseStatus) -> () ) {
        self.iAPWrapper.purchase(product: product) { (status, product, transaction) in
            print("PURCHASE \(String(describing: product?.title)) with status \(status.message)")
            completion(status)
            self.iAPWrapper.getReceipt(isNeedToUpdate: self.receiptAlwaysFromServer) { (receipt) in
                self.delegate?.DTPurchaseReturn(receipt: receipt, after: .purchase)
            }
        }
    }
    
    public func restorePurchase(completion: @escaping (DTPurchaseStatus) -> ()) {
        self.iAPWrapper.restorePurchase { (status, product, transaction) in
            completion(status)
            self.iAPWrapper.getReceipt(isNeedToUpdate: self.receiptAlwaysFromServer) { (receipt) in
                self.delegate?.DTPurchaseReturn(receipt: receipt, after: .restore)
            }
        }
    }
    
    public func cleanData() {
        defaults.set(nil, forKey: DTDefaultsKeys.iap_purchase_cache)
    }
    
    /// Request receipt
    /// - Parameters:
    ///   - isNeedToUpdate: forcibly get from server
    ///   - completion: callback block
    func getReceipt(isNeedToUpdate: Bool, completion: @escaping (String) -> Void) {
        self.iAPWrapper.getReceipt(isNeedToUpdate: isNeedToUpdate, completion: completion)
    }
    
}

// MARK: - For cache products

extension DTIAPProvider {
    
    /// запись продуктов в кеш
    private func save2UserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.availableProduct) {
            defaults.set(encoded, forKey: DTDefaultsKeys.iap_purchase_cache)
        }
    }
    
    /// получение продуктов из кеша если нет инета
    private func getProductsFromUserDefaults() {
        if let savedProducts = defaults.object(forKey: DTDefaultsKeys.iap_purchase_cache) as? Data {
            let decoder = JSONDecoder()
            if let products = try? decoder.decode([DTIAPProduct].self, from: savedProducts) {
                self.availableProduct = products
            }
        }
    }
}


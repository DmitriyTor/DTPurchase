//
//  IAPProvider.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import UIKit

public final class DTIAPProvider {
    
    public weak var delegate: DTPurchaseDelegate?
    
    private let defaults = UserDefaults.standard
    let iAPWrapper = DTIAPWrapper()
    
    public init(delegate: DTPurchaseDelegate?) {
        self.delegate = delegate
        self.setProductIds()
    }
    
    private func setProductIds() {
        guard let delegate = self.delegate else {
            fatalError("Delegate is nil!")
        }
        self.iAPWrapper.setProductIds(ids: delegate.getProductIDs())
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
            }
        }
    }
}

extension DTIAPProvider: DTIAPProviderProtocol {

    /// Доступные продукты
    public func getAvailableItem(completion: @escaping([DTIAPProduct]) -> Void) {
        if self.availableProduct.count > 0 {
            completion(self.availableProduct)
        } else {
            self.fetchProducts(completion: completion)
        }
        
    }
    
    /// Метод осуществление покупки продукта
    public func purchaseProduct(product: DTIAPProduct, completion: @escaping (DTPurchaseStatus) -> () ) {
        self.iAPWrapper.purchase(product: product) { (status, product, transaction) in
            print("PURCHASE \(String(describing: product?.title)) with status \(status.message)")
            completion(status)
        }
    }
    
    public func restorePurchase(completion: @escaping (DTPurchaseStatus) -> ()) {
        self.iAPWrapper.restorePurchase { (status, product, transaction) in
            completion(status)
        }
    }
    
    public func cleanData() {
        defaults.set(nil, forKey: DTDefaultsKeys.iap_purchase_cache)
    }
    
//    /// отправка ресепта в случае запуска приложения раз в 4 дня
//    func sendBackgroundReceipt() {
//        let currentDate = Date()
//        guard let lastSendDay = self.getLastReceiptSendDate() else {
//            self.sendReceipt2Server(receiptIsFromServer: true) { (error) in
//                if error == nil {
//                    self.setLastReceiptSendDate()
//                }
//            }
//            return
//        }
//        let diffInDays = Calendar.current.dateComponents([.day], from: currentDate, to: lastSendDay).day ?? 5
//        if diffInDays > 4 {
//            self.sendReceipt2Server(receiptIsFromServer: true) { (error) in
//                if error == nil {
//                    self.setLastReceiptSendDate()
//                }
//            }
//        }
//    }
    
}

// MARK: - For cache products

extension DTIAPProvider {
    
    /// запись продуктов в кеш
    func save2UserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.availableProduct) {
            defaults.set(encoded, forKey: DTDefaultsKeys.iap_purchase_cache)
        }
    }
    
    /// получение продуктов из кеша если нет инета
    func getProductsFromUserDefaults() {
        if let savedProducts = UserDefaults.standard.object(forKey: DTDefaultsKeys.iap_purchase_cache) as? Data {
            let decoder = JSONDecoder()
            if let products = try? decoder.decode([DTIAPProduct].self, from: savedProducts) {
                self.availableProduct = products
            }
        }
    }
    
    /// сохранения дня отправки ресепта
    func setLastReceiptSendDate() {
        let encoder = JSONEncoder()
        let date = Date()
        if let data = try? encoder.encode(date) {
            defaults.set(data, forKey: DTDefaultsKeys.receipt_last_date)
        }
    }
    
    /// День отправки ресепта последний раз
    func getLastReceiptSendDate() -> Date? {
        if let savedDate = UserDefaults.standard.object(forKey: DTDefaultsKeys.receipt_last_date) as? Data {
            let decoder = JSONDecoder()
            if let date = try? decoder.decode(Date.self, from: savedDate) {
                return date
            }
        }
        return nil
    }
}


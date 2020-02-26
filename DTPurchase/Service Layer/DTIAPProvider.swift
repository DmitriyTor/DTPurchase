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
    let iAPWrapper = DTIAPWrapper()
    
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
}


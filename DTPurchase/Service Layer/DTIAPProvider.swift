//
//  IAPProvider.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import UIKit

public final class DTIAPProvider {

    // MARK: - Properties
    private let defaults: UserDefaults
    private let iAPWrapper = DTIAPWrapper()
    private var availableProduct = [DTIAPProduct]()

    /// Delegate for extension your purchase class (f.e. can return receipt)
    public weak var delegate: DTPurchaseDelegate?

    /// If server - receipt get from Apple Server and then returned in DTPurchaseReturn(receipt...) func
    var receiptFrom: DTPurchaseReceiptType

    /// Init with get products ids from Info.plist by key DTPurchase!
    /// - Parameter defaults: UserDefaults - Optional parameter
    /// - Parameter getReceiptFrom: From where return receipt (server\device)
    public init(on defaults: UserDefaults = UserDefaults.standard,
                getReceiptFrom: DTPurchaseReceiptType = .device) {
        self.defaults = defaults
        self.receiptFrom = getReceiptFrom
        self.setProductIds()
    }

    /// Init with id purchase in init
    /// - Parameters:
    ///     - productIDs: product ids from appstore connet
    ///     - defaults: UserDefaults - Optional parameter
    ///     - getReceiptFrom: From where return receipt (server\device)
    public init(productIDs: [String],
                on defaults: UserDefaults = UserDefaults.standard,
                getReceiptFrom: DTPurchaseReceiptType = .device) {
        self.defaults = defaults
        self.receiptFrom = getReceiptFrom
        self.setProductIds(productIDs: productIDs)
    }

}

// MARK: - Private
extension DTIAPProvider {

    private func setProductIds(productIDs: [String]? = nil) {
        if let ids = productIDs {
            self.iAPWrapper.setProductIds(ids: ids)
            self.fetchProducts(completion: nil)
            return
        }
        guard let ids = UIApplication.productIDs else {
            fatalError("Set array of ids in Info.plist by key DTPurchase!")
        }
        self.iAPWrapper.setProductIds(ids: ids)
        self.fetchProducts(completion: nil)
    }

    /// Get products from Apple server
    private func fetchProducts(completion: (([DTIAPProduct]) -> Void)?) {
        self.iAPWrapper.fetchAvailableProducts { (products, status) in
            if status.status != .fetched {
                self.getProductsFromUserDefaults()
            } else {
                self.availableProduct = products
                completion?(self.availableProduct)
                self.save2UserDefaults()
                self.iAPWrapper.getReceipt(from: self.receiptFrom) { (receipt) in
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

    /// Force update products
    /// - Parameter completion: callback block with products
    public func updateAvailableItem(completion: @escaping([DTIAPProduct]) -> Void) {
        self.fetchProducts(completion: completion)
    }

    /// Method for bought product
    /// - Parameters:
    ///     - product: product
    ///     - completion: callback block
    public func purchaseProduct(product: DTIAPProduct, completion: @escaping (DTPurchaseStatus) -> ()) {
        self.iAPWrapper.purchase(product: product) { (status, product, transaction) in
            completion(status)
            self.iAPWrapper.getReceipt(from: self.receiptFrom) { (receipt) in
                self.delegate?.DTPurchaseReturn(receipt: receipt, after: .purchase)
            }
        }
    }

    /// Restore purchase
    /// - Parameter completion: callback block
    public func restorePurchase(completion: @escaping (DTPurchaseStatus) -> ()) {
        self.iAPWrapper.restorePurchase { (status, product, transaction) in
            completion(status)
            self.iAPWrapper.getReceipt(from: self.receiptFrom) { (receipt) in
                self.delegate?.DTPurchaseReturn(receipt: receipt, after: .restore)
            }
        }
    }

    /// Clean local products
    public func cleanData() {
        defaults.set(nil, forKey: DTDefaultsKeys.iap_purchase_cache)
    }

    /// Request receipt
    /// - Parameters:
    ///   - isNeedToUpdate: forcibly get from server
    ///   - completion: callback block
    func getReceipt(from type: DTPurchaseReceiptType, completion: @escaping (String) -> Void) {
        self.iAPWrapper.getReceipt(from: type, completion: completion)
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


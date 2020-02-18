//
//  IAPProduct.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation
import StoreKit

public struct DTIAPProduct: Codable {
    
    public let productIdentifier: String
    public let price: Int
    public let title: String
    public let description: String
    public let priceLocale: String
    
    internal init(product: SKProduct) {
        self.productIdentifier = product.productIdentifier
        self.price = product.price.intValue
        self.title = product.localizedTitle
        self.description = product.localizedDescription
        self.priceLocale = product.localizedPrice
    }
}

extension DTIAPProduct: Equatable {
    
}

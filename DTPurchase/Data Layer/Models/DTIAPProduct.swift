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
    public let price: Double
    public let title: String
    public let description: String
    public let priceLocale: String
    public let subscriptionPeriod: DTProductSubscriptionPeriod?

    internal init(product: SKProduct) {
        self.productIdentifier = product.productIdentifier
        self.price = product.price.doubleValue
        self.title = product.localizedTitle
        self.description = product.localizedDescription
        self.priceLocale = product.localizedPrice

        if #available(iOS 11.2, *), let period = product.subscriptionPeriod, let periodUnit = DTPeriodUnit(rawValue: period.unit.rawValue) {
            self.subscriptionPeriod = DTProductSubscriptionPeriod(numberOfUnits: period.numberOfUnits, unit: periodUnit)
        } else {
            self.subscriptionPeriod = nil
        }
    }

    public enum DTPeriodUnit: UInt, Codable, Equatable {
        case day = 0
        case week
        case month
        case year
    }

    public struct DTProductSubscriptionPeriod: Codable, Equatable {

        public var numberOfUnits: Int
        public var unit: DTPeriodUnit
    }
}

extension DTIAPProduct: Equatable {
    public static func == (lhs: DTIAPProduct, rhs: DTIAPProduct) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier
            && lhs.price == rhs.price
            && lhs.title == rhs.title
            && lhs.description == rhs.description
            && lhs.priceLocale == rhs.priceLocale
            && lhs.subscriptionPeriod == rhs.subscriptionPeriod
    }
}

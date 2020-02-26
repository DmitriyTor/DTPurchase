//
//  DTPurchaseStatus.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation

public struct DTPurchaseStatus {
    
    public var status: DTPurchaseStatusCommon
    public var detailError: String?
}

public enum DTPurchaseStatusCommon {
    
    case setProductIds
    case disabled
    case restored
    case purchased
    case failedBuy
    case failedFetch
    case fetched
    
    var message: String{
        switch self {
        case .setProductIds: return "Product ids not set, call setProductIds method!"
        case .disabled: return "Purchases are disabled in your device!"
        case .restored: return "You've successfully restored your purchase!"
        case .purchased: return "You've successfully bought this purchase!"
        case .failedBuy: return "Error while trying to buy! :("
        case .failedFetch: return "Error while trying to fetch! :("
        case .fetched: return "Fetched successful!"
        }
    }
}

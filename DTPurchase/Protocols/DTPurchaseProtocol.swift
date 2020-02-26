//
//  DTPurchaseProtocol.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation

public enum DTPurchaseReceiptAction {
    case purchase
    case restore
    case fetch
}

public protocol DTPurchaseDelegate: class {
    
    /// Methods return receipt after action
    /// - Parameter receipt: current receipt
    /// - Parameter action: which action was
    func DTPurchaseReturn(receipt: String, after action: DTPurchaseReceiptAction)
}

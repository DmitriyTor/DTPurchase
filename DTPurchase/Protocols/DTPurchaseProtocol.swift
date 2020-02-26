//
//  DTPurchaseProtocol.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation

public protocol DTIAPProviderProtocol {
    
    /// Method for bought product
    /// - Parameter product: product
    /// - Parameter completion: callback block
    func purchaseProduct(product: DTIAPProduct, completion: @escaping (DTPurchaseStatus) -> () )
    
    /// List of available products
    func getAvailableItem(completion: @escaping([DTIAPProduct]) -> Void)
    
    /// Восстановление покупок
    func restorePurchase(completion: @escaping (DTPurchaseStatus) -> ())
    
    //очистка кеша покупок
    func cleanData()
}

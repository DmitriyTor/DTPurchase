//
//  DTPurchaseProtocol.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation

public protocol DTIAPProviderProtocol {
    
    /// Метод покупки продукта
    /// - Parameter product: сам продукт
    /// - Parameter completion: комплишн блок с статусом
    func purchaseProduct(product: DTIAPProduct, completion: @escaping (DTPurchaseStatus) -> () )
    
    /// Список доступных продуктов
    func getAvailableItem(completion: @escaping([DTIAPProduct]) -> Void)
    
    /// Восстановление покупок
    func restorePurchase(completion: @escaping (DTPurchaseStatus) -> ())
    
    //очистка кеша покупок
    func cleanData()
}

public protocol DTPurchaseDelegate: class {
    
    func getProductIDs() -> [String]
}

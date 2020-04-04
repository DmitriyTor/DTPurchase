//
//  NumberFormatter+Extension.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 18.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import Foundation

extension NumberFormatter {
    
    func currencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}

//
//  UIApplication+Extension.swift
//  DTPurchase
//
//  Created by Дмитрий Торопкин on 26.02.2020.
//  Copyright © 2020 Dmitriy Toropkin. All rights reserved.
//

import UIKit

extension UIApplication {
    static var productIDs: [String]? {
        return Bundle.main.object(forInfoDictionaryKey: "DTPurchase") as? [String]
    }
}

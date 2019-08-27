//
//  CoreStrings.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/27/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import Foundation

public enum CoreStrings {
    
    static let userNotCreated = "User is not created".localized()

    public static let ok = "OK".localized()
}

extension String {
    
    public func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

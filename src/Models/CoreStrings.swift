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
    static let userNotAuthenticated = "User is not authenticated".localized()
    static let emptyUserID = "User ID is empty".localized()
    static let fileNotFound = "File not found".localized()
    static let downloadURLNotExisting = "Download URL does not exist".localized()
    static let broadcastInfoKey = "broadcast.info.key"

    public static let ok = "OK".localized()
}

extension String {
    
    public func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

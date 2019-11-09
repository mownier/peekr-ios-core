//
//  User.swift
//  Peekr
//
//  Created by Mounir Ybanez on 10/19/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import Foundation

public struct User: Hashable {

    public let id: String
    public let username: String
    public let avatar: String
    
    public init(id: String = "", username: String = "", avatar: String = "") {
        self.id = id
        self.username = username
        self.avatar = avatar
    }
    
    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

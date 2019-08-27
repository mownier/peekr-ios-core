//
//  CoreError.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/26/19.
//  Copyright © 2019 Nir. All rights reserved.
//

public struct CoreError: Error {
    
    public let code: Int
    public let message: String
}

public func coreError(
    code: Int = 0,
    message: String = "") -> CoreError {
    return CoreError(code: code, message: message)
}

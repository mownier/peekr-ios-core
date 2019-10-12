//
//  Triple.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/26/19.
//  Copyright © 2019 Nir. All rights reserved.
//

public struct Triple<F, S, T> {
    
    public let first: F
    public let second: S
    public let third: T
}

public func tripleOf<F,S,T>(_ first: F, _ second: S, _ third: T) -> Triple<F, S, T> {
    return Triple(first: first, second: second, third: third)
}

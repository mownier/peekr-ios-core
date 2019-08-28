//
//  Pair.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/26/19.
//  Copyright © 2019 Nir. All rights reserved.
//

public struct Pair<F, S> {
    
    public let first: F
    public let second: S
}

public func pairWith<F, S>(first: F, second: S) -> Pair<F, S> {
    return Pair(first: first, second: second)
}

//
//  Either.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/26/19.
//  Copyright © 2019 Nir. All rights reserved.
//

public enum Either<L, R: Error> {
    
    case left(L)
    case right(R)
}

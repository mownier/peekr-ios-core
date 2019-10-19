//
//  ImageFile.swift
//  Peekr
//
//  Created by Mounir Ybanez on 9/27/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import Foundation

public struct ImageFile {

    public let id: String
    public let height: Double
    public let width: Double
    public let downloadURLString: String
}

extension ImageFile {
    
    func toDictionary() -> [String : Any] {
        return [
            "id" : id,
            "height" : height,
            "width" : width,
            "download_url" : downloadURLString
        ]
    }
}

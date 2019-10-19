//
//  VideoFile.swift
//  Peekr
//
//  Created by Mounir Ybanez on 9/28/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import Foundation

public struct VideoFile {
    
    public let id: String
    public let height: Double
    public let width: Double
    public let downloadURLString: String
}

extension VideoFile {
    
    func toDictionary() -> [String : Any] {
        return [
            "id" : id,
            "height" : height,
            "width" : width,
            "download_url" : downloadURLString
        ]
    }
}

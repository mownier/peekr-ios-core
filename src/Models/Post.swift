//
//  Post.swift
//  Peekr
//
//  Created by Mounir Ybanez on 10/12/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import Foundation

public struct Post {

    public let id: String
    public let authorID: String
    public let message: String
    public let thumbnail: ImageFile
    public let video: VideoFile
    public let createdOn: Date?
    public let updatedOn: Date?
}

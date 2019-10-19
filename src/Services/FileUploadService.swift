//
//  FileUploadService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 9/14/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

public func uploadJPEGImage(with url: URL?, track: @escaping (Progress?) -> Void, completion: @escaping (Result<ImageFile>) -> Void) {
    let childPath: (String) -> String = { userID -> String in
        let key = Date.timeIntervalSinceReferenceDate * 1000
        return "\(userID)/images/\(key).jpg"
    }
    
    let metadata: (URL) -> StorageMetadata? = { url -> StorageMetadata? in
        let size = UIImage(contentsOfFile: url.path)!.size
        let metadata = StorageMetadata()
        metadata.customMetadata = ["height": "\(size.height)", "width": "\(size.width)"]
        metadata.contentType = "image/jpeg"
        return metadata
    }
    
    let data: (URL) -> Data = { url -> Data in
        return UIImage(contentsOfFile: url.path)!
            .jpegData(compressionQuality: 0.9)!
    }
    
    uploadFile(
        with: url,
        childPath: childPath,
        metadata: metadata,
        data: data,
        track: track,
        completion: { result in
            switch result {
            case let .notOkay(error):
                completion(.notOkay(error))
            
            case let .okay(triple):
                let db = Firestore.firestore()
                let batch = db.batch()
                
                let downloadURLString = triple.first
                let metadata = triple.second?.customMetadata ?? [:]
                let userID = triple.third
                let height: Double = Double(metadata["height"] ?? "") ?? 0.0
                let width: Double = Double(metadata["width"] ?? "") ?? 0.0
                let uploadedOn = Timestamp(date: Date())
                
                // Write to 'images' collection
                let imagesCollection = db.collection("images")
                let imageDocID = imagesCollection.document().documentID
                let imageDocData: [String: Any] = [
                    "id" : imageDocID,
                    "user_id" : userID,
                    "download_url" : downloadURLString,
                    "height" : height,
                    "width" : width,
                    "uploaded_on": uploadedOn,
                ]
                let imageDoc = imagesCollection.document(imageDocID)
                batch.setData(imageDocData, forDocument: imageDoc)
                
                // Write to 'user_images' collection
                let userImagesCollection = db.collection("user_images")
                let userImageDoc = userImagesCollection.document(userID)
                let userImageDocData: [String: Any] = [
                    imageDocID : ["uploaded_on": uploadedOn],
                ]
                batch.setData(userImageDocData, forDocument: userImageDoc, merge: true)
                
                batch.commit { error in
                    guard error == nil else {
                        completion(.notOkay(coreError(message: error!.localizedDescription)))
                        return
                    }
                    
                    let imageFile = ImageFile(
                        id: imageDocID,
                        height: height,
                        width: width,
                        downloadURLString: downloadURLString,
                        uploadedOn: uploadedOn.dateValue()
                    )
                    completion(.okay(imageFile))
                }
            }
    })
}

public func uploadMP4Video(with url: URL?, track: @escaping (Progress?) -> Void, completion: @escaping (Result<VideoFile>) -> Void) {
    let childPath: (String) -> String = { userID -> String in
        let key = Date.timeIntervalSinceReferenceDate * 1000
        return "\(userID)/vidoes/\(key).mp4"
    }
    
    let metadata: (URL) -> StorageMetadata? = { url -> StorageMetadata? in
        let size: CGSize
        
        if let track = AVAsset(url: url).tracks(withMediaType: AVMediaType.video).first {
            size = track.naturalSize.applying(track.preferredTransform)
            
        } else {
            size = .zero
        }
        
        let metadata = StorageMetadata()
        metadata.customMetadata = ["height": "\(size.height)", "width": "\(size.width)"]
        metadata.contentType = "video/mp4"
        return metadata
    }
    
    let data: (URL) -> Data = { url -> Data in
        return try! Data(contentsOf: url)
    }
    
    uploadFile(
        with: url,
        childPath: childPath,
        metadata: metadata,
        data: data,
        track: track,
        completion: { result in
            switch result {
            case let .notOkay(error):
                completion(.notOkay(error))
                
            case let .okay(triple):
                let db = Firestore.firestore()
                let batch = db.batch()
                
                let downloadURLString = triple.first
                let metadata = triple.second?.customMetadata ?? [:]
                let userID = triple.third
                let height: Double = Double(metadata["height"] ?? "") ?? 0.0
                let width: Double = Double(metadata["width"] ?? "") ?? 0.0
                let uploadedOn = Timestamp(date: Date())
                
                // Write to 'videos' collection
                let collection = db.collection("videos")
                let videoDocID = collection.document().documentID
                let videoDocData: [String: Any] = [
                    "id" : videoDocID,
                    "user_id" : userID,
                    "download_url" : downloadURLString,
                    "height" : height,
                    "width" : width,
                    "uploaded_on": uploadedOn,
                    ]
                let videoDoc = collection.document(videoDocID)
                batch.setData(videoDocData, forDocument: videoDoc)
                
                // Write to 'user_videos' collection
                let userVideosCollection = db.collection("user_videos")
                let userVideoDoc = userVideosCollection.document(userID)
                let userVideoDocData: [String: Any] = [
                    videoDocID: ["uploaded_on": uploadedOn],
                ]
                batch.setData(userVideoDocData, forDocument: userVideoDoc, merge: true)
                
                batch.commit { error in
                    guard error == nil else {
                        completion(.notOkay(coreError(message: error!.localizedDescription)))
                        return
                    }
                    
                    let videoFile = VideoFile(
                        id: videoDocID,
                        height: height,
                        width: width,
                        downloadURLString: downloadURLString,
                        uploadedOn: uploadedOn.dateValue()
                    )
                    completion(.okay(videoFile))
                }
            }
    })
}

func uploadFile(
    with url: URL?,
    childPath: (String) -> String,
    metadata: (URL) -> StorageMetadata?,
    data: (URL) -> Data,
    track: @escaping (Progress?) -> Void,
    completion: @escaping (Result<Triple<String, StorageMetadata?, String>>) -> Void) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    
    guard let fileURL = url  else {
        completion(.notOkay(coreError(message: CoreStrings.fileNotFound)))
        return
    }
    
    let storageChildPath = childPath(userID)
    let storageMetadata = metadata(fileURL)
    
    let storageRef = Storage.storage().reference()
    let childRef = storageRef.child(storageChildPath)
    childRef.putData(
        data(fileURL),
        metadata: storageMetadata,
        completion: { metadata, error in
            guard error == nil else {
                completion(.notOkay(coreError(message: error!.localizedDescription)))
                return
            }
            
            childRef.downloadURL(completion: { downloadURL, error in
                guard error == nil else {
                    completion(.notOkay(coreError(message: error!.localizedDescription)))
                    return
                }
                
                guard let downloadURLString = downloadURL?.absoluteString else {
                    completion(.notOkay(coreError(message: CoreStrings.downloadURLNotExisting)))
                    return
                }
                
                completion(.okay(tripleOf(downloadURLString, storageMetadata, userID)))
            })
            
    }).observe(.progress, handler: { snapshot in
        track(snapshot.progress)
    })
}

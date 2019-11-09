//
//  PostSharerService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 10/12/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

public func sharePost(
    with message: String,
    imageURL: URL?,
    videoURL: URL?,
    track: @escaping (Double) -> Void,
    completion: @escaping (Result<Post>) -> Void
) {
    // 45% for uploading image, 45% for uploading video
    let progressFactor: Double = 0.45
    
    uploadJPEGImage(
        with: imageURL,
        track: { progress in
            let fractionCompleted = progress?.fractionCompleted ?? 0.0
            track(fractionCompleted * progressFactor)
            
    }, completion: { imageResult in
        switch imageResult {
        case let .notOkay(error):
            completion(.notOkay(error))
        
        case let .okay(imageFile):
            uploadMP4Video(
                with: videoURL,
                track: { progress in
                    let fractionCompleted = progress?.fractionCompleted ?? 0.0
                    track((fractionCompleted * progressFactor) + progressFactor)
                    
            }, completion: { videoResult in
                switch videoResult {
                case let .notOkay(error):
                    completion(.notOkay(error))
                
                case let .okay(videoFile):
                    sharePost(with: message, thumbnail: imageFile, video: videoFile) { postResult in
                        switch postResult {
                        case .okay: track(1.0)
                        default: break
                        }
                        completion(postResult)
                    }
                }
            })
        }
    })
}

public func sharePost(
    with message: String,
    thumbnail: ImageFile,
    video: VideoFile,
    completion: @escaping (Result<Post>) -> Void
) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    
    let nowDate = Date()
    let createdOn = Timestamp(date: nowDate)
    let updatedOn = Timestamp(date: nowDate)
    
    let db = Firestore.firestore()
    let batch = db.batch()
    
    // Write to 'posts' collection
    let postsCollection = db.collection("posts")
    let postDocID = postsCollection.document().documentID
    let postDoc = postsCollection.document(postDocID)
    let postDocData: [String : Any] = [
        "id" : postDocID,
        "author_id" : userID,
        "message" : message,
        "thumbnail" : thumbnail.toDictionary().convertDateToFirebaseTimestamp(),
        "video" : video.toDictionary().convertDateToFirebaseTimestamp(),
        "created_on" : createdOn,
        "updated_on" : updatedOn
    ]
    batch.setData(postDocData, forDocument: postDoc)
    
    batch.commit { error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        
        completion(.okay(Post(
            id: postDocID,
            authorID: userID,
            message: message,
            thumbnail: thumbnail,
            video: video,
            createdOn: createdOn.dateValue(),
            updatedOn: updatedOn.dateValue()
        )))
    }
}

extension Dictionary where Key == String, Value == Any {
    
    func convertDateToFirebaseTimestamp() -> [String: Any] {
        return mapValues({ value -> Any in
            if let dictionary = value as? [String: Any] {
                return dictionary.convertDateToFirebaseTimestamp()
            }
            guard let date = value as? Date else {
                return value
            }
            return Timestamp(date: date)
        })
    }
}

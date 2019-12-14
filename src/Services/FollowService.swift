//
//  FollowService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 12/14/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

public func followUser(withID id: String, completion: @escaping (Result<String>) -> Void) {
    followOrUnfollowUser(withID: id, action: .follow, completion: completion)
}

public func unfollowUser(withID id: String, completion: @escaping (Result<String>) -> Void) {
    followOrUnfollowUser(withID: id, action: .unfollow, completion: completion)
}

enum FollowUnfollowAction: Int {
    
    case follow = 1
    case unfollow = -1
}

func followOrUnfollowUser(
    withID id: String,
    action: FollowUnfollowAction,
    completion: @escaping (Result<String>) -> Void
) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    guard !id.isEmpty else {
        completion(.notOkay(coreError(message: CoreStrings.emptyUserID)))
        return
    }
    let db = Firestore.firestore()
    let userPublicInfoCollection = db.collection("user_public_info")
    let targetUserDoc = userPublicInfoCollection.document(id)
    let currentUserDoc = userPublicInfoCollection.document(userID)
    db.runTransaction({ transaction, errorPointer -> Any? in
        let targetUserDocSnapshot: DocumentSnapshot
        let currentUserDocSnapshot: DocumentSnapshot
        do {
            try targetUserDocSnapshot = transaction.getDocument(targetUserDoc)
            try currentUserDocSnapshot = transaction.getDocument(currentUserDoc)
            
        } catch let fetchError as NSError {
            errorPointer?.pointee = fetchError
            return nil
        }
        let oldFollowerCount = targetUserDocSnapshot.data()?["follower_count"] as? Int ?? 0
        let oldFollowingCount = currentUserDocSnapshot.data()?["following_count"] as? Int ?? 0
        let newFollowerCount = oldFollowerCount == 0 && action == .unfollow
            ? 0
            : oldFollowerCount + action.rawValue
        let newFollowingCount = oldFollowingCount == 0 && action == .unfollow
            ? 0
            : oldFollowingCount + action.rawValue
        transaction.updateData(["follower_count": newFollowerCount], forDocument: targetUserDoc)
        transaction.updateData(["following_count": newFollowingCount], forDocument: currentUserDoc)
        return nil
    }) { _, error in
        guard error == nil else {
            completion(.notOkay((error!)))
            return
        }
        completion(.okay(""))
    }
    // follow/unfollow a user
    // user_public_info collection
    // /<userID>/following_count += 1 (-1)
    // /<id>/follower_count += 1 (-1)
}

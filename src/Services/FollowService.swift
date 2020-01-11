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

public func isFollowingUser(withID id: String, completion: @escaping (Result<Bool>) -> Void) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    guard !id.isEmpty else {
        completion(.notOkay(coreError(message: CoreStrings.emptyUserID)))
        return
    }
    let db = Firestore.firestore()
    let listCollection = db.collection("following/\(userID)/list")
    let listDoc = listCollection.document(id)
    listDoc.getDocument { snapshot, error in
        guard error == nil else {
            completion(.notOkay(error!))
            return
        }
        guard let snapshot = snapshot,
            snapshot.exists else {
                completion(.okay(false))
                return
        }
        completion(.okay(true))
    }
}

public func getFollowersOfUser(
    withID id: String,
    startAfter lastID: String? = nil,
    count: UInt = 10,
    completion: @escaping (Result<[User]>) -> Void
) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    guard !userID.isEmpty, !id.isEmpty else {
        completion(.notOkay(coreError(message: CoreStrings.emptyUserID)))
        return
    }
    let count = count > 0 ? count : 10
    let db = Firestore.firestore()
    let listCollection = db.collection("followers/\(id)/list")
    let query = listCollection.limit(to: Int(count))
    let resultBlock: FIRQuerySnapshotBlock = { snapshot, error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        guard let snapshot = snapshot else {
            completion(.notOkay(coreError(message: CoreStrings.dataNotFound)))
            return
        }
        let listOfUserID = snapshot
            .documents
            .compactMap({ $0.data()["id"] as? String })
        getUsers(withIDs: Set(listOfUserID)) { setOfUser in
            let userIDAndIndex = listOfUserID.enumerated()
            let orderedList = setOfUser.sorted { user1, user2 -> Bool in
                let index1 = userIDAndIndex.first(where: { $0.element == user1.id })?.offset ?? -1
                let index2 = userIDAndIndex.first(where: { $0.element == user2.id })?.offset ?? -1
                return index1 < index2
            }
            completion(.okay(orderedList))
        }
    }
    guard let lastID = lastID, !lastID.isEmpty else {
        query.getDocuments { snapshot, error in
            resultBlock(snapshot, error)
        }
        return
    }
    let listDoc = listCollection.document(lastID)
    listDoc.getDocument { snapshot, error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        guard let snapshot = snapshot else {
            completion(.notOkay(coreError(message: CoreStrings.dataNotFound)))
            return
        }
        query.start(afterDocument: snapshot).getDocuments { snapshot, error in
            resultBlock(snapshot, error)
        }
    }
}

public func getMyFollowers(
    startAfter userID: String? = nil,
    count: UInt = 10,
    completion: @escaping (Result<[User]>) -> Void
) {
    getFollowersOfUser(
        withID: Auth.auth().currentUser?.uid ?? "",
        startAfter: userID,
        count: count,
        completion: completion
    )
}

public func getListThatUserHasFollowed(
    userID id: String,
    startAfter lastID: String? = nil,
    count: UInt = 10,
    completion: @escaping (Result<[User]>) -> Void
) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    guard !userID.isEmpty, !id.isEmpty else {
        completion(.notOkay(coreError(message: CoreStrings.emptyUserID)))
        return
    }
    let count = count > 0 ? count : 10
    let db = Firestore.firestore()
    let listCollection = db.collection("following/\(id)/list")
    let query = listCollection.limit(to: Int(count))
    let resultBlock: FIRQuerySnapshotBlock = { snapshot, error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        guard let snapshot = snapshot else {
            completion(.notOkay(coreError(message: CoreStrings.dataNotFound)))
            return
        }
        let listOfUserID = snapshot
            .documents
            .compactMap({ $0.data()["id"] as? String })
        getUsers(withIDs: Set(listOfUserID)) { setOfUser in
            let userIDAndIndex = listOfUserID.enumerated()
            let orderedList = setOfUser.sorted { user1, user2 -> Bool in
                let index1 = userIDAndIndex.first(where: { $0.element == user1.id })?.offset ?? -1
                let index2 = userIDAndIndex.first(where: { $0.element == user2.id })?.offset ?? -1
                return index1 < index2
            }
            completion(.okay(orderedList))
        }
    }
    guard let lastID = lastID, !lastID.isEmpty else {
        query.getDocuments { snapshot, error in
            resultBlock(snapshot, error)
        }
        return
    }
    let listDoc = listCollection.document(lastID)
    listDoc.getDocument { snapshot, error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        guard let snapshot = snapshot else {
            completion(.notOkay(coreError(message: CoreStrings.dataNotFound)))
            return
        }
        query.start(afterDocument: snapshot).getDocuments { snapshot, error in
            resultBlock(snapshot, error)
        }
    }
}

public func getUsersIHaveFollowed(
    startAfter lastUserID: String? = nil,
    count: UInt = 10,
    completion: @escaping (Result<[User]>) -> Void
) {
    getListThatUserHasFollowed(
        userID: Auth.auth().currentUser?.uid ?? "",
        startAfter: lastUserID,
        count: count,
        completion: completion
    )
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
    guard !id.isEmpty, !userID.isEmpty else {
        completion(.notOkay(coreError(message: CoreStrings.emptyUserID)))
        return
    }
    let db = Firestore.firestore()
    let followersCollection = db.collection("followers")
    let targetUserFollowersDoc = followersCollection.document(id)
    let targetUserFollowersListCollection = targetUserFollowersDoc.collection("list")
    let targetUserFollowersListCurrentUserDoc = targetUserFollowersListCollection.document(userID)
    let followingCollection = db.collection("following")
    let currentUserFollowingDoc = followingCollection.document(userID)
    let currentUserFollowingListCollection = currentUserFollowingDoc.collection("list")
    let currentUserFollowingListTargetUserDoc = currentUserFollowingListCollection.document(id)
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
        switch action {
        case .unfollow:
            currentUserFollowingListTargetUserDoc.delete()
            targetUserFollowersListCurrentUserDoc.delete()
            
        case .follow:
            transaction.setData(["id": id], forDocument: currentUserFollowingListTargetUserDoc)
            transaction.setData(["id": userID], forDocument: targetUserFollowersListCurrentUserDoc)
        }
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

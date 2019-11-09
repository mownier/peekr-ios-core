//
//  UserService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 11/9/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

public func getUsers(withIDs set: Set<String>, completion: @escaping (Set<User>) -> Void) {
    guard Auth.auth().currentUser != nil else {
        completion([])
        return
    }
    let db = Firestore.firestore()
    let userPublicInfoCollection = db.collection("user_public_info")
    var userQueryCounter = 0
    var users: Set<User> = []
    let userQueryResultBlock: (DocumentSnapshot?, Error?) -> Bool = { snapshot, error in
        userQueryCounter += 1
        let isFinished = userQueryCounter >= set.count
        guard error == nil else {
            return isFinished
        }
        if let user: User = snapshot?.data()?.toUser(), !user.id.isEmpty {
            users.insert(user)
        }
        return isFinished
    }
    set.forEach({ userID  in
        let userDoc = userPublicInfoCollection.document(userID)
        userDoc.getDocument(completion: { snapshot, error in
            guard userQueryResultBlock(snapshot, error) else {
                return
            }
            completion(users)
        })
    })
}

extension Dictionary where Key == String, Value == Any {
    
    func toUser() -> User {
        return User(
            id: self["id"] as? String ?? "",
            username: self["username"] as? String ?? "",
            avatar: self["avatar"] as? String ?? ""
        )
    }
}

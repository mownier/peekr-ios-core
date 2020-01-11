//
//  NewsFeedService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 10/19/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

// Get all posts from each followed user
// for the last 5 (default) days.
// If there are no posts for the last
// 5 days, load 50 (default) recent posts
// from each user.
// This includes his/her posts.
public func getNewsFeed(
    limit: UInt = 50,
    previousDays: UInt = 5,
    completion: @escaping (Result<Pair<Set<User>, [Post]>>) -> Void
) {
    guard let userID = Auth.auth().currentUser?.uid else {
        completion(.notOkay(coreError(message: CoreStrings.userNotAuthenticated)))
        return
    }
    let db = Firestore.firestore()
    // Get all user ids that the signed in user is following
    let userFollowingCollection = db.collection("following/\(userID)/list")
    userFollowingCollection.getDocuments { snapshot, error in
        guard error == nil else {
            completion(.notOkay(coreError(message: error!.localizedDescription)))
            return
        }
        let postsCollection = db.collection("posts")
        let userIDs: Set<String> = Set([
            [userID],
            snapshot?
                .documents
                .compactMap({ $0.data()["id"] as? String }) ?? []
        ].joined()
            .map({ $0 })
            .filter({ !$0.isEmpty }))
        getUsers(withIDs: userIDs, completion: { users in
            var postQueryCounter: Int = 0
            var posts: [Post] = []
            let postQueryResultBlock: (QuerySnapshot?, Error?) -> Bool = { snapshot, error in
                postQueryCounter += 1
                let isFinished = postQueryCounter >= users.count
                guard error == nil else {
                    return isFinished
                }
                let postsData = snapshot?.documents.map({ $0.data() }) ?? []
                posts.append(contentsOf:
                    postsData
                        .map({ $0.toPost() })
                        .filter({ !$0.id.isEmpty && !$0.authorID.isEmpty })
                )
                return isFinished
            }
            let maxDate = Date()
            let minDate = Calendar.current.date(byAdding: Calendar.Component.day, value: -Int(previousDays), to: maxDate)!
            let maxTimestamp = Timestamp(date: maxDate)
            let minTimestamp = Timestamp(date: minDate)
            users.forEach({ user in
                // Query for the last 5 (default) days
                postsCollection
                    .whereField("author_id", isEqualTo: user.id)
                    .whereField("created_on", isLessThanOrEqualTo: maxTimestamp)
                    .whereField("created_on", isGreaterThanOrEqualTo: minTimestamp)
                    .order(by: "created_on", descending: true)
                    .limit(to: Int(limit))
                    .getDocuments(completion: { snapshot, error in
                        guard postQueryResultBlock(snapshot, error) else {
                            return
                        }
                        let usersWithNoPosts = users.filter({ user -> Bool in
                            return !posts.contains(where: { $0.authorID == user.id })
                        })
                        if usersWithNoPosts.count == 0 {
                            completion(.okay(Pair(first: users, second: posts)))
                            return
                        }
                        postQueryCounter -= usersWithNoPosts.count
                        usersWithNoPosts.forEach({ user in
                            // Query for the 50 (default) recent posts
                            postsCollection
                                .whereField("author_id", isEqualTo: user.id)
                                .order(by: "created_on", descending: true)
                                .limit(to: Int(limit))
                                .getDocuments(completion: { snapshot, error in
                                    guard postQueryResultBlock(snapshot, error) else {
                                        return
                                    }
                                    completion(.okay(Pair(first: users, second: posts)))
                                })
                        })
                    })
            })
        })
    }
}

extension Dictionary where Key == String, Value == Any {
    
    func toPost() -> Post {
        let thumbnailData = self["thumbnail"] as? [String: Any] ?? [:]
        let videoData = self["video"] as? [String: Any] ?? [:]
        let thumbnail = ImageFile(
            id: thumbnailData["id"] as? String ?? "",
            height: thumbnailData["height"] as? Double ?? 0.0,
            width: thumbnailData["width"] as? Double ?? 0.0,
            downloadURLString: thumbnailData["download_url"] as? String ?? "",
            uploadedOn: (self["uploaded_on"] as? Timestamp)?.dateValue()
        )
        let video = VideoFile(
            id: videoData["id"] as? String ?? "",
            height: videoData["height"] as? Double ?? 0.0,
            width: videoData["width"] as? Double ?? 0.0,
            downloadURLString: videoData["download_url"] as? String ?? "",
            uploadedOn: (self["uploaded_on"] as? Timestamp)?.dateValue()
        )
        return Post(
            id: self["id"] as? String ?? "",
            authorID: self["author_id"] as? String ?? "",
            message: self["message"] as? String ?? "",
            thumbnail: thumbnail,
            video: video,
            createdOn: (self["created_on"] as? Timestamp)?.dateValue(),
            updatedOn: (self["updated_on"] as? Timestamp)?.dateValue()
        )
    }
}

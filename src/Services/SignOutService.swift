//
//  SignOutService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/28/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth

public func signOut(completion: @escaping (Result<String>) -> Void) {
    DispatchQueue.main.async {
        do {
            try Auth.auth().signOut()
        } catch {}
        completion(.okay(CoreStrings.ok))
    }
}

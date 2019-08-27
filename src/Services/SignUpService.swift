//
//  SignUpService.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/26/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import FirebaseAuth

public func signUpWith(email: String = "", password: String = "", completion: @escaping (Result<String>) -> Void) {
    Auth.auth().createUser(withEmail: email, password: password) { result, error in
        if error != nil {
            completion(.notOkay(error!))
            return
        }
        
        if result?.user == nil {
            completion(.notOkay(coreError(message: Strings.userNotCreated)))
            return
        }
        
        completion(.okay(Strings.ok))
    }
}

//
//  CoreViewController.swift
//  Peekr
//
//  Created by Mounir Ybanez on 8/28/19.
//  Copyright © 2019 Nir. All rights reserved.
//

import UIKit

public func viewControllerFromStoryboardWith<T: UIViewController>(name: String) -> T {
    let bundle = Bundle(for: T.self)
    let storyboard = UIStoryboard(name: name, bundle: bundle)
    let screen = storyboard.instantiateViewController(withIdentifier: String(describing: T.self)) as! T
    return screen
}

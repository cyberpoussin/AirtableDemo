//
//  Services+init.swift
//  Services+init
//
//  Created by Admin on 01/09/2021.
//

import Foundation

extension Services {
    public init() {
        self.init(networkService: URLSession.shared, keyValueService: UserDefaults.standard)
    }
}

//
//  UserCases.swift
//  UserCases
//
//  Created by Admin on 01/09/2021.
//

import Foundation
import Combine


class UserUseCase {
    let services: Services
    init(services: Services = Services()) {
        self.services = services
    }
    
    func getUsersOneByOne() -> AnyPublisher<FinalUser, NetworkRequestError> {
        services.networkService
            .run(.fetchAllUsers())
            .map {
                return $0.allObjects
            }
            .flatMap {
                $0.publisher
            }
            .flatMap { [services] (user: ATUser) -> AnyPublisher<FinalUser, NetworkRequestError> in
                services.networkService.run(.fetchBurgers(ids: user.burgers))
                    .map {
                        FinalUser(networkRecord: user, burgers: $0.allObjects)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getAllUsers() -> AnyPublisher<[FinalUser], NetworkRequestError> {
        getUsersOneByOne()
            .collect()
            .eraseToAnyPublisher()
    }
    
}

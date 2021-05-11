//
//  BurgerService.swift
//  PromoAvril
//
//  Created by Admin on 28/04/2021.
//

import Foundation
import Combine

func fetchUsers() -> AnyPublisher<(Data, URLResponse), URLError>{
    let url = URL(string: "https://api.airtable.com/v0/appKEnC4TluRHoXr7/Users?api_key=keyXSumLVSJRFmMRd")!
    return URLSession.shared.dataTaskPublisher(for: url)
        .map {
            print($0)
            return $0
        }
        .eraseToAnyPublisher()
}

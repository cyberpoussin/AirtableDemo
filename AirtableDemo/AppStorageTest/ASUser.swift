//
//  ASUser.swift
//  PromoAvril
//
//  Created by Admin on 04/05/2021.
//

import Foundation




struct ASPlaces: Codable, Identifiable {
    var id: UUID = .init()
    var latitude: Double
    var longitude: Double
}




struct ASUser: Codable {
    var name: String
    var firstName: String
    var age: Int
    var places: [ASPlaces]


    enum CodingKeys: CodingKey {
        case name, firstName, age, places
    }
    
    init(name: String, firstName: String, age: Int, places: [ASPlaces]) {
        self.name = name
        self.firstName = firstName
        self.age = age
        self.places = places
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        firstName = try container.decode(String.self, forKey: .firstName)
        age = try container.decode(Int.self, forKey: .age)
        places = try container.decode([ASPlaces].self, forKey: .places)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(age, forKey: .age)
        try container.encode(places, forKey: .places)

        // <and so on>
    }
}


extension ASUser: RawRepresentable {
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode(ASUser.self, from: data)
        else {
            print("erreur decod")
            return nil
        }
        print(result)
        self = result
    }
    
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            print("erreur")
            return "[]"
        }
        print(result)
        return result
    }
}

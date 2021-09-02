//
//  Endpoint.swift
//  Endpoint
//
//  Created by Admin on 01/09/2021.
//

import Foundation

struct ATEndpoint<Response: Decodable>: RequestBuilder {
    var request: URLRequest {
        var request = URLRequest(url: url)
        request.httpBody = data
        return request
    }
    var url: URL
    var data: Data?
    enum Get {
        case fetchAllUsers, fetchBurgers(ids: [String])
    }
    enum Post {
        case postUser
    }
    
    typealias ResponseType = Response
    
    init(_ endpoint: Get) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appKEnC4TluRHoXr7"
        let queryItems = [URLQueryItem(name: "api_key", value: "keyXSumLVSJRFmMRd")]
        
        switch endpoint {
        case .fetchAllUsers:
            components.path += "/Users"
            components.queryItems = queryItems
            self.url = components.url!
        case let .fetchBurgers(ids):
            components.path += "/Burgers"
            components.queryItems = queryItems
            var formula: String = "OR("
            var formulaElements: String = ""
            for id in ids {
                formulaElements += ",RecordId=\"\(id)\""
            }
            formulaElements = String(formulaElements.dropFirst())
            formula += formulaElements + ")"
            print(formula)
            components.queryItems?.append(URLQueryItem(name: "filterByFormula", value: formula))
            self.url = components.url!
        }
    }
    
    init<Body: Encodable>(_ endpoint: Post, body: Body? = nil) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appKEnC4TluRHoXr7"
        let queryItems = [URLQueryItem(name: "api_key", value: "keyXSumLVSJRFmMRd")]
        
        switch endpoint {
        case .postUser:
            self.data = try? JSONEncoder().encode(body)
            components.path += "/Users"
            components.queryItems = queryItems
            self.url = components.url!
        }
    }
}

extension RequestBuilder where Self == ATEndpoint<ATResponse<[ATUser]>>  {
    static func fetchAllUsers() -> ATEndpoint<ATResponse<[ATUser]>> {
        return ATEndpoint(.fetchAllUsers)
    }
}

extension RequestBuilder where Self == ATEndpoint<ATResponse<[ATBurger]>>  {
    static func fetchBurgers(ids: [String]) -> ATEndpoint<ATResponse<[ATBurger]>> {
        return ATEndpoint(.fetchBurgers(ids: ids))
    }
}

//
//  Services.swift
//  Services
//
//  Created by Admin on 01/09/2021.
//

import Combine
import Foundation


public protocol NetworkService {
    func run<T: Decodable>(request: URLRequest) -> AnyPublisher<T, NetworkRequestError>
    
    func run<Builder: RequestBuilder>(_: Builder) -> AnyPublisher<Builder.ResponseType, NetworkRequestError>
}

public enum NetworkRequestError: LocalizedError, Equatable {
    case invalidRequest
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case error4xx(_ code: Int)
    case serverError
    case error5xx(_ code: Int)
    case decodingError
    case urlSessionFailed(_ error: URLError)
    case unknownError
}

public protocol RequestBuilder {
    associatedtype ResponseType: Decodable
    var request: URLRequest {get}
}

public protocol KeyValueService: AnyObject {
    subscript<C: Codable>(key key: String, type type: C.Type) -> C? { get set }
}

public struct Services {
    public init(networkService: NetworkService, keyValueService: KeyValueService) {
        self.networkService = networkService
        self.keyValueService = keyValueService
    }
    
    let networkService: NetworkService
    let keyValueService: KeyValueService
}

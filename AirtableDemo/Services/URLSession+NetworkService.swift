//
//  URLSession+NetworkService.swift
//  URLSession+NetworkService
//
//  Created by Admin on 01/09/2021.
//

import Combine
import Foundation


private func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 402, 405...499: return .error4xx(statusCode)
        case 500: return .serverError
        case 501...599: return .error5xx(statusCode)
        default: return .unknownError
        }
}


    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NetworkRequestError
func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError:
            return .decodingError
        case let urlError as URLError:
            return .urlSessionFailed(urlError)
        case let error as NetworkRequestError:
            return error
        default:
            return .unknownError
        }
    }
extension URLSession: NetworkService {
    public func run<T>(request: URLRequest) -> AnyPublisher<T, NetworkRequestError> where T : Decodable {
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap {(data, response) -> Data in
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkRequestError.unknownError
                }
                switch response.statusCode {
                case 200...299: return data
                default: throw httpError(response.statusCode)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError {
                handleError($0)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public func run<Endpoint: RequestBuilder>(_ builder: Endpoint) -> AnyPublisher<Endpoint.ResponseType, NetworkRequestError>{
            run(request: builder.request)
    }
}

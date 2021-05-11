
import SwiftUI
import Combine
struct UserBGRequest: Decodable {
    var records: [UserBG]
}

struct UserBG: Decodable {
    let idBG: String
    let name: String
    let status: String?
    let notes: String?
    let burgers: [String]?
    
    enum OuterKeys: String, CodingKey {
        case idBG = "id"
        case fields = "fields"
    }
    
    enum FieldsKeys: String, CodingKey {
        case name = "Name"
        case status = "Status"
        case notes = "Notes"
        case burgers = "Burgers"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OuterKeys.self)
        idBG = try container.decode(String.self, forKey: .idBG)
        let fields = try container.nestedContainer(keyedBy: FieldsKeys.self, forKey: .fields)
        name = try fields.decode(String.self, forKey: .name)
        status = try fields.decodeIfPresent(String.self, forKey: .status)
        notes = try fields.decodeIfPresent(String.self, forKey: .notes)
        burgers = try fields.decodeIfPresent([String].self, forKey: .burgers)

    }
}

protocol ATObject: Decodable {
    var id: String? {get set}
}

struct ATResponse<T: ATObject>: Decodable {
    var records: [ATRecord<T>]
    var allObjects: [T] {
        records.map {$0.object}
    }
}

struct ATRecord<T: ATObject>: Decodable {
    var idRecord: String
    var fields: T
    
    enum CodingKeys: String, CodingKey {
        case idRecord = "id"
        case fields = "fields"
    }
    var object: T {
        var record = fields
        record.id = idRecord
        return record
    }
}

struct ATUser: ATObject {
    var id: String? = nil
    let name: String
    let status: String?
    let notes: String?
    var burgers: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case status = "Status"
        case notes = "Notes"
        case burgers = "Burgers"
    }
}

struct ATBurger: ATObject {
    var id: String? = nil
    let name: String
    let notes: String
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case notes = "Notes"
    }
}


struct FinalUser {
    var id: String? = nil
    let name: String
    let status: String?
    let notes: String?
    var burgers: [FinalBurger]
    
    init(networkRecord:ATRecord<ATUser>, burgers: [ATBurger] = []) {
        id = networkRecord.idRecord
        name = networkRecord.fields.name
        status = networkRecord.fields.status
        notes = networkRecord.fields.notes
        self.burgers = burgers.map({FinalBurger(networkRecord: $0)})
    }
}

struct FinalBurger {
    let name: String
    let description: String
    init(networkRecord: ATBurger) {
        name = networkRecord.name
        description = networkRecord.notes
    }
}


enum NetworkRequestError: LocalizedError, Equatable {
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

func fetch<T:Decodable>(request: Endpoint<T>) -> AnyPublisher<T, NetworkRequestError>{
    return URLSession.shared.dataTaskPublisher(for: request.url)
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




let json = """
{
    "records": [
        {
            "id": "recGXoXC0DNUd3LUp",
            "fields": {
                "Name": "Jean",
                "Notes": "C'est un bon",
                "Status": "Todo"
            },
            "createdTime": "2021-04-28T16:03:28.000Z"
        }
    ],
    "offset": "rec9aS707BQlJpHNB"
}
"""
let jsonData = json.data(using: .utf8)

func decode<T: Decodable>(data: Data) -> T? {
    let decoder = JSONDecoder()
    var result: T? = nil
    do {
        result = try decoder.decode(T.self, from: data)
    } catch {
        print(error)
    }
    return result
}

enum Endpoint<ResponseType> {
    case fetchAllUsers, fetchBurgers(ids: [String])
    var responseType: Any.Type {
        switch self {
        case .fetchAllUsers:
            return ATResponse<ATUser>.self
        case .fetchBurgers:
            return ATResponse<ATBurger>.self
        }
    }
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appKEnC4TluRHoXr7"
        let queryItems = [URLQueryItem(name: "api_key", value: "keyXSumLVSJRFmMRd")]
        
        switch self {
        case .fetchAllUsers:
            components.path += "/Users"
            components.queryItems = queryItems
            return components.url!
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
            return components.url!
        }
    }
}

func stillFetch<T: Decodable>(request: Endpoint<T>, completion: @escaping (T?) -> ()) {
    let task = URLSession.shared.dataTask(with: request.url) {data,response,error in
        guard error == nil else {
            print("error : \(String(describing: error))")
            return
        }
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            print("erreur http")
            return
        }
        guard let data = data else {
            print("no data")
            return
        }
        
        let result: T? = decode(data: data)
        completion(result)
    }
    task.resume()
}


//stillFetch(request: .fetchAllUsers) {(result: ATResponse<ATUser>?) in
//    guard let result = result else { return }
//    let userRecords: [ATRecord<ATUser>] = result.records
//    var finalUsers: [FinalUser] = []
//    for userRecord in userRecords {
//        group.enter()
//        stillFetch(request: .fetchBurgers(ids: userRecord.object.burgers)) { (result: ATResponse<ATBurger>?) in
//            guard let result = result else {return}
//            print("des burgers :")
//            finalUsers.append(FinalUser(networkRecord: userRecord, burgers: result.allObjects))
//            print(finalUsers)
//            group.leave()
//        }
//    }
//    group.notify(queue: .main) {
//
//        print(finalUsers)
//
//    }
//}






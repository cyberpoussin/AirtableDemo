
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

struct ATResponse<T: Collection>: Decodable where T.Element: ATObject {
    var records: [ATRecord<T.Element>]

    var allObjects: [T.Element] {
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


struct FinalUser: Identifiable {
    var id: String? = nil
    let name: String
    let status: String?
    let notes: String?
    var burgers: [FinalBurger]
    
    init(networkRecord: ATUser, burgers: [ATBurger] = []) {
        id = networkRecord.id
        name = networkRecord.name
        status = networkRecord.status
        notes = networkRecord.notes
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












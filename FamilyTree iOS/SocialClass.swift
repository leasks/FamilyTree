//
//  SocialClass.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 11/10/2023.
//

import Foundation

struct SocialClass: Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var affiliationIDs: Set<UUID>?
    var wealth: Float = -1
    
    // Computed property for backward compatibility
    var affiliations: Set<Affiliation>? {
        get {
            guard let ids = affiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            affiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, startDate, endDate, affiliationIDs, wealth
    }
    
    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, affiliationIDs: Set<UUID>? = nil, wealth: Float = -1) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.affiliationIDs = affiliationIDs
        self.wealth = wealth
    }
}
extension SocialClass: Hashable {
    static func == (lhs: SocialClass, rhs: SocialClass) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

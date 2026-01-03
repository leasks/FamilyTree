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
        case id, name, startDate, endDate, affiliations, wealth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.wealth = try container.decodeIfPresent(Float.self, forKey: .wealth) ?? -1
        
        // Decode affiliations as full objects if present
        let affiliationsDecoded = try container.decodeIfPresent(Set<Affiliation>.self, forKey: .affiliations)
        self.affiliationIDs = affiliationsDecoded != nil ? Set(affiliationsDecoded!.map { $0.id }) : nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(wealth, forKey: .wealth)
        
        // Encode affiliations as full objects if present
        if let affiliationIDs = affiliationIDs {
            let affiliations = Set(affiliationIDs.compactMap { ConfigLoader.findAffiliation(byID: $0) })
            if !affiliations.isEmpty {
                try container.encode(affiliations, forKey: .affiliations)
            }
        }
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

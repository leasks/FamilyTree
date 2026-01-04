//
//  Affiliation.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Affiliation: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case likedAffiliations
        case dislikedAffiliations
        case startDate
        case endDate
        case capital
        case colour
    }

    let id: UUID
    var name: String
    var likedAffiliationIDs: Set<UUID>? = []
    var dislikedAffiliationIDs: Set<UUID>? = []
    var startDate: Date?
    var endDate: Date?
    var capitalID: UUID?
    var conversionAffiliation: String?
    var colour: Int

    // Computed properties for backward compatibility
    var likedAffiliations: Set<Affiliation>? {
        get {
            guard let ids = likedAffiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            likedAffiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }

    var dislikedAffiliations: Set<Affiliation>? {
        get {
            guard let ids = dislikedAffiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            dislikedAffiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }

    var capital: Town? {
        get {
            guard let id = capitalID else { return nil }
            return ConfigLoader.findLocation(byID: id) as? Town
        }
        set {
            capitalID = newValue?.id
        }
    }

    init(from decoder: Decoder) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        let hexColour = try container.decodeIfPresent(String.self, forKey: .colour) ?? "0xD3D3D3"
        self.colour = Int(hexColour.dropFirst(2), radix: 16) ?? 0

        // Decode liked affiliations as strings and convert to UUIDs
        let strLikedAffils = try container.decodeIfPresent([String].self, forKey: .likedAffiliations)
        var likedIDs: Set<UUID> = []
        for afilName in strLikedAffils ?? [] {
            if let afilID = ConfigLoader.findAffiliationID(byName: afilName) {
                likedIDs.insert(afilID)
            }
        }
        self.likedAffiliationIDs = likedIDs.isEmpty ? nil : likedIDs

        // Decode disliked affiliations as strings and convert to UUIDs
        let strDislikedAffils = try container.decodeIfPresent([String].self, forKey: .dislikedAffiliations)
        var dislikedIDs: Set<UUID> = []
        for afilName in strDislikedAffils ?? [] {
            if let afilID = ConfigLoader.findAffiliationID(byName: afilName) {
                dislikedIDs.insert(afilID)
            }
        }
        self.dislikedAffiliationIDs = dislikedIDs.isEmpty ? nil : dislikedIDs

        let strStartDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        if strStartDate != nil {
            self.startDate = dateFormatter.date(from: strStartDate!)
        }
        let strEndDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        if strEndDate != nil {
            self.endDate = dateFormatter.date(from: strEndDate!)
        }

        // Look up the capital through its name from the ConfigLoader
        let strCapital = try container.decode(String.self, forKey: .capital)
        self.capitalID = (ConfigLoader.locations.first(where: {$0.name == strCapital && $0.type == .town}) as? Town)?.id
        print(strCapital)
        print(ConfigLoader.locations.first(where: {$0.name == strCapital}) == nil)
        print(self.capital == nil)
    }

    func encode(to encoder: Encoder) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)

        // Encode colour as hex string
        let hexColour = String(format: "0x%06X", colour)
        try container.encode(hexColour, forKey: .colour)

        // Encode liked affiliations as array of names
        if let likedIDs = likedAffiliationIDs {
            let likedNames = likedIDs.compactMap { ConfigLoader.findAffiliation(byID: $0)?.name }
            if !likedNames.isEmpty {
                try container.encode(likedNames, forKey: .likedAffiliations)
            }
        }

        // Encode disliked affiliations as array of names
        if let dislikedIDs = dislikedAffiliationIDs {
            let dislikedNames = dislikedIDs.compactMap { ConfigLoader.findAffiliation(byID: $0)?.name }
            if !dislikedNames.isEmpty {
                try container.encode(dislikedNames, forKey: .dislikedAffiliations)
            }
        }

        // Encode dates as formatted strings
        if let startDate = startDate {
            try container.encode(dateFormatter.string(from: startDate), forKey: .startDate)
        }
        if let endDate = endDate {
            try container.encode(dateFormatter.string(from: endDate), forKey: .endDate)
        }

        // Encode capital as name
        if let capitalID = capitalID, let capital = ConfigLoader.findLocation(byID: capitalID) {
            try container.encode(capital.name, forKey: .capital)
        }
    }

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.colour = 0xFF0000
    }

    mutating func removeDislikedAffiliation(affiliation: Affiliation) {
        dislikedAffiliationIDs?.remove(affiliation.id)
    }
}

extension Affiliation: Hashable {
    static func == (lhs: Affiliation, rhs: Affiliation) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

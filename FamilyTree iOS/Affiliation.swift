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
        self.likedAffiliationIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .likedAffiliations)
        self.dislikedAffiliationIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .dislikedAffiliations)
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

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.colour = 0xFF0000
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

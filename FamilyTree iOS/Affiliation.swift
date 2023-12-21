//
//  Affiliation.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Affiliation: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case likedAffiliations
        case dislikedAffiliations
        case startDate
        case endDate
        case capital
        case colour
    }

    var name: String
    var likedAffiliations: Set<Affiliation>? = []
    var dislikedAffiliations: Set<Affiliation>? = []
    var startDate: Date?
    var endDate: Date?
    var capital: Town?
    var conversionAffiliation: String?
    var colour: Int

    init(from decoder: Decoder) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        let hexColour = try container.decodeIfPresent(String.self, forKey: .colour) ?? "0xD3D3D3"
        self.colour = Int(hexColour.dropFirst(2), radix: 16) ?? 0
        self.likedAffiliations = try container.decodeIfPresent(Set<Affiliation>.self, forKey: .likedAffiliations)
        self.dislikedAffiliations = try container.decodeIfPresent(Set<Affiliation>.self, forKey: .dislikedAffiliations)
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
        self.capital = ConfigLoader.locations.first(where: {$0.name == strCapital && $0.type == .town}) as? Town
        print(strCapital)
        print(ConfigLoader.locations.first(where: {$0.name == strCapital}) == nil)
        print(self.capital == nil)
    }

    init(name: String) {
        self.name = name
        self.colour = 0xFF0000
    }
}

extension Affiliation: Hashable {
    static func == (lhs: Affiliation, rhs: Affiliation) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

//
//  Cure.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Cure: Codable {
    let id: UUID
    var startDate: Date
    var locationID: UUID?
    
    // Computed property for backward compatibility
    var location: Location? {
        get {
            guard let id = locationID else { return nil }
            return ConfigLoader.findLocation(byID: id)
        }
        set {
            locationID = newValue?.id
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, startDate, location
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        
        // Decode location as full object if present
        let locationDecoded = try container.decodeIfPresent(Location.self, forKey: .location)
        self.locationID = locationDecoded?.id
    }
    
    init(id: UUID = UUID(), startDate: Date, locationID: UUID? = nil) {
        self.id = id
        self.startDate = startDate
        self.locationID = locationID
    }
}

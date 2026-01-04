//
//  Location.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

enum LocationType: String, Codable {
    case town
    case county
    case region
    case country
}

class Location: Codable, Hashable, @unchecked Sendable {
    let id: UUID
    var name: String
    var type: LocationType = .town

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }

}


class Region: Location {
    override var type: LocationType {
        get {
            return .region
        }

        set {
            super.type = newValue
        }
    }
}

class County: Location {
    private enum CodingKeys: String, CodingKey {
        case region
    }

    override var type: LocationType {
        get {
            return .county
        }

        set {
            super.type = newValue
        }
    }
    var regionID: UUID
    
    // Computed property for backward compatibility
    var region: Region {
        get {
            return ConfigLoader.findLocation(byID: regionID) as! Region //swiftlint:disable:this force_cast
        }
        set {
            regionID = newValue.id
        }
    }

    init(id: UUID = UUID(), name: String, regionID: UUID) {
        self.regionID = regionID
        super.init(id: id, name: name)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let strRegion = try container.decode(String.self, forKey: .region)
        guard let region = ConfigLoader.locations.first(where: {$0.name == strRegion && $0.type == .region}) as? Region else {
            throw DecodingError.dataCorruptedError(forKey: .region, in: container,
                                                    debugDescription: "Region '\(strRegion)' not found in ConfigLoader")
        }
        self.regionID = region.id
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode region name instead of UUID
        if let region = ConfigLoader.findLocation(byID: regionID) {
            try container.encode(region.name, forKey: .region)
        }
        
        try super.encode(to: encoder)
    }

    static func == (lhs: County, rhs: County) -> Bool {
        return lhs.id == rhs.id
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class Town: Location {
    private enum CodingKeys: String, CodingKey {
        case founded
        case county
        case foundedBy
        case abandoned
        case ruler
        case rulers
        case longitude
        case latitude
    }

    enum Infrastructure: String {
        case acqueduct
        case hospital
    }

    override var type: LocationType {
        get {
            return .town
        }

        set {
            super.type = newValue
        }
    }
    var founded: Int
    var countyID: UUID
    var foundedByID: UUID?
    let abandoned: Int?
    var rulerIDs: [Int: UUID] = [:]
    var rulerID: UUID?
    var longitude: Double?
    var latitutde: Double?
    var infrastructure: [Infrastructure] = []
    
    // Computed properties for backward compatibility
    var county: County {
        get {
            return ConfigLoader.findLocation(byID: countyID) as! County //swiftlint:disable:this force_cast
        }
        set {
            countyID = newValue.id
        }
    }
    
    var foundedBy: Affiliation? {
        get {
            guard let id = foundedByID else { return nil }
            return ConfigLoader.findAffiliation(byID: id)
        }
        set {
            foundedByID = newValue?.id
        }
    }
    
    var ruler: Affiliation? {
        get {
            guard let id = rulerID else { return nil }
            return ConfigLoader.findAffiliation(byID: id)
        }
        set {
            rulerID = newValue?.id
        }
    }
    
    var rulers: [Int: Affiliation] {
        get {
            var result: [Int: Affiliation] = [:]
            for (year, id) in rulerIDs {
                if let affiliation = ConfigLoader.findAffiliation(byID: id) {
                    result[year] = affiliation
                }
            }
            return result
        }
        set {
            rulerIDs = [:]
            for (year, affiliation) in newValue {
                rulerIDs[year] = affiliation.id
            }
        }
    }

    init(id: UUID = UUID(), name: String, founded: Int, countyID: UUID, foundedByID: UUID? = nil, abandoned: Int? = nil) {
        self.founded = founded
        self.countyID = countyID
        self.foundedByID = foundedByID
        self.abandoned = abandoned

        super.init(id: id, name: name)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.founded = try container.decode(Int.self, forKey: .founded)
        self.abandoned = try container.decodeIfPresent(Int.self, forKey: .abandoned)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.latitutde = try container.decodeIfPresent(Double.self, forKey: .latitude)
        let strCurRuler = try container.decodeIfPresent(String.self, forKey: .ruler)
        if let strCurRuler = strCurRuler {
            self.rulerID = ConfigLoader.affiliations.first(where: {$0.name == strCurRuler})?.id
        }

        let strRulers = try container.decodeIfPresent([Int: String].self, forKey: .rulers) ?? [:]
        for (year, ruling) in strRulers {
            self.rulerIDs[year] = ConfigLoader.affiliations.first(where: {$0.name == ruling})?.id
        }

        let strFoundedBy = try container.decodeIfPresent(String.self, forKey: .foundedBy)
        if let strFoundedBy = strFoundedBy {
            self.foundedByID = ConfigLoader.affiliations.first(where: {$0.name == strFoundedBy})?.id
        }
        else
        {
            self.foundedByID = nil
        }
        let strCounty = try container.decode(String.self, forKey: .county)
        self.countyID = (ConfigLoader.locations.first(where: {$0.name == strCounty && $0.type == .county}) as? County)?.id
            ?? County(name: strCounty, regionID: Region(name: "Unspecified").id).id

        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(founded, forKey: .founded)
        try container.encodeIfPresent(abandoned, forKey: .abandoned)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(latitutde, forKey: .latitude)
        
        // Encode ruler name instead of UUID
        if let rulerID = rulerID, let ruler = ConfigLoader.findAffiliation(byID: rulerID) {
            try container.encode(ruler.name, forKey: .ruler)
        }
        
        // Encode rulers as dictionary of year -> name
        if !rulerIDs.isEmpty {
            var rulerNames: [Int: String] = [:]
            for (year, rulerID) in rulerIDs {
                if let ruler = ConfigLoader.findAffiliation(byID: rulerID) {
                    rulerNames[year] = ruler.name
                }
            }
            if !rulerNames.isEmpty {
                try container.encode(rulerNames, forKey: .rulers)
            }
        }
        
        // Encode foundedBy name instead of UUID
        if let foundedByID = foundedByID, let foundedBy = ConfigLoader.findAffiliation(byID: foundedByID) {
            try container.encode(foundedBy.name, forKey: .foundedBy)
        }
        
        // Encode county name instead of UUID
        if let county = ConfigLoader.findLocation(byID: countyID) {
            try container.encode(county.name, forKey: .county)
        }
        
        try super.encode(to: encoder)
    }

    func createRulerEvents(year: Int) -> Event? {
        guard let newRuler = rulers[year] else { return nil }
        
        let eventName = newRuler.name + " conquers " + self.name
        var rulerChangeEvent = Event(name: eventName, description: eventName, triggerYear: year)
        rulerChangeEvent.location = [self]

        // Add injuries if hostile
        // TODO: Need to add War/Battle Wounds too
        if let currentRuler = self.ruler {
            if (currentRuler.dislikedAffiliations?.contains(newRuler) ?? false) ||
                (newRuler.dislikedAffiliations?.contains(currentRuler) ?? false) {
                if let killedInjury = ConfigLoader.injuries.first(where: {$0.name == "Killed In Battle"}) {
                    rulerChangeEvent.injuriesAdded = [killedInjury]
                }
            }

            // Conversion details
            if let conversionAfil = ConfigLoader.affiliations.first(where: {
                $0.name == (newRuler.conversionAffiliation ?? newRuler.name)
            }) {
                rulerChangeEvent.convertAffiliation[currentRuler] = conversionAfil
            }

            return rulerChangeEvent

        }

        return nil
    }

    static func == (lhs: Town, rhs: Town) -> Bool {
        return lhs.id == rhs.id
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

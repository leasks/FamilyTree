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

class Location: Codable, Hashable {
    var name: String
    var type: LocationType = .town

    init(name: String) {
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.name == rhs.name
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
    var region: Region

    init(name: String, region: Region) {
        self.region = region
        super.init(name: name)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let strRegion = try container.decode(String.self, forKey: .region)
        self.region = (ConfigLoader.locations.first(where: {$0.name == strRegion && $0.type == .region}) as? Region)!
        try super.init(from: decoder)
    }

    static func == (lhs: County, rhs: County) -> Bool {
        return lhs.name == rhs.name && lhs.region == rhs.region
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(region)
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
    var county: County
    var foundedBy: Affiliation?
    let abandoned: Int?
    var rulers: [Int: Affiliation] = [:]
    var ruler: Affiliation?
    var longitude: Double?
    var latitutde: Double?
    var infrastructure: [Infrastructure] = []

    init(name: String, founded: Int, county: County, foundedBy: Affiliation? = nil, abandoned: Int? = nil) {
        self.founded = founded
        self.county = county
        self.foundedBy = foundedBy
        self.abandoned = abandoned

        super.init(name: name)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.founded = try container.decode(Int.self, forKey: .founded)
        self.abandoned = try container.decodeIfPresent(Int.self, forKey: .abandoned)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.latitutde = try container.decodeIfPresent(Double.self, forKey: .latitude)
        let strCurRuler = try container.decodeIfPresent(String.self, forKey: .ruler)
        if strCurRuler != nil {
            self.ruler = ConfigLoader.affiliations.first(where: {$0.name == strCurRuler})
        }

        let strRulers = try container.decodeIfPresent([Int: String].self, forKey: .rulers) ?? [:]
        for (year, ruling) in strRulers {
            self.rulers[year] = ConfigLoader.affiliations.first(where: {$0.name == ruling})
        }

        let strFoundedBy = try container.decodeIfPresent(String.self, forKey: .foundedBy)
        if strFoundedBy != nil {
            self.foundedBy = ConfigLoader.affiliations.first(where: {$0.name == strFoundedBy})
        }
        else
        {
            self.foundedBy = nil
        }
        let strCounty = try container.decode(String.self, forKey: .county)
        self.county = (ConfigLoader.locations.first(where: {$0.name == strCounty && $0.type == .county}) as? County)
            ?? County(name: strCounty, region: Region(name: "Unspecified"))

        try super.init(from: decoder)
    }

    func createRulerEvents(year: Int) -> Event? {
        if rulers[year] != nil {
            let eventName = rulers[year]!.name + " conquers " + self.name
            var rulerChangeEvent = Event(name: eventName, description: eventName, triggerYear: year)
            rulerChangeEvent.location = [self]

            // Add injuries if hostile
            // TODO: Need to add War/Battle Wounds too
            if self.ruler != nil {
                if (self.ruler!.dislikedAffiliations?.contains(rulers[year]!) ?? false) ||
                    (rulers[year]!.dislikedAffiliations?.contains(self.ruler!) ?? false) {
                    rulerChangeEvent.injuriesAdded = [ConfigLoader.injuries.first(where: {$0.name == "Killed In Battle"})!]
                }

                // Conversion details
                let conversionAfil = ConfigLoader.affiliations.first(where: {
                    $0.name == (rulers[year]!.conversionAffiliation ?? rulers[year]!.name)
                })
                rulerChangeEvent.convertAffiliation[self.ruler!] = conversionAfil
            }

            return rulerChangeEvent

        }

        return nil
    }

    static func == (lhs: Town, rhs: Town) -> Bool {
        return lhs.name == rhs.name && lhs.founded == rhs.founded && lhs.county == rhs.county
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(county)
        hasher.combine(founded)
    }
}

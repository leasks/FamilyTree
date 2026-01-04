//
//  Rates.swift
//  FamilyTree
//
//  Created by Stephen Leask on 31/07/2023.
//

import Foundation

struct RateAgeRanges: Codable {
    var startAge: Int? = 0
    var endAge: Int? = 1000
    var rate: Float
}
extension RateAgeRanges: Hashable {
    static func == (lhs: RateAgeRanges, rhs: RateAgeRanges) -> Bool {
        return lhs.startAge == rhs.startAge && lhs.endAge == rhs.endAge && lhs.rate == rhs.rate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(startAge)
        hasher.combine(endAge)
        hasher.combine(rate)
    }
}

class Rates: Codable {
    let id: UUID
    var type: String
    var startDate: Date?
    var endDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case startDate
        case endDate
    }
    
    init(id: UUID = UUID()) {
        self.id = id
        self.type = ""
    }
    
    init(id: UUID = UUID(), type: String) {
        self.id = id
        self.type = type
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decode(String.self, forKey: .type)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
    }
    
    func getRate(person: Person? = nil) -> Float { return 0 }

    func apply(person: Person, game: GameEngine) async { }
}
extension Rates: Hashable {
    static func == (lhs: Rates, rhs: Rates) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class AgeBasedRates: Rates {
    var rates: Set<RateAgeRanges>?

    private enum CodingKeys: String, CodingKey {
        case rates
    }
    
    init(id: UUID = UUID(), rates: Set<RateAgeRanges>) {
        self.rates = rates
        
        super.init(id: id)
    }
    
    init(id: UUID = UUID(), rates: Set<RateAgeRanges>, type: String) {
        self.rates = rates
        super.init(id: id, type: type)
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rates = try container.decode(Set<RateAgeRanges>.self, forKey: .rates)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rates, forKey: .rates)
        
        try super.encode(to: encoder)
    }

    override func getRate(person: Person? = nil) -> Float {
        guard let person = person else { return 0 }
        let age = person.age
        return rates?.first(where: {($0.startAge ?? 0) <= age && ($0.endAge ?? 1000) > age})?.rate ?? 0
    }
    
    override func apply(person: Person, game: GameEngine) async {
        // TODO: This is assuming always trying for children, need to include indicator of trying influenced by number of children rate
        let gameD = await game.getGameDate()
        let minD = await game.getMinDate()
        let maxD = await game.getMaxDate()
        if (self.startDate ?? minD) > gameD || (self.endDate ?? maxD) < gameD { return }
        let rate = getRate(person: person)
        switch self.type {
        case "Fertility":
            if Float.random(in: 0...1) < rate {
                await person.hasChild(game: game)
            }
            
        case "Marriage":
            if Float.random(in: 0...1) < rate {
                await person.marries(game: game, minAge: self.rates?.first?.startAge ?? 0)
            }
            
        case "Mortality":
            let rand = Float.random(in: 0...rate)
            person.health -= rand
            if person.health <= 0 || rate >= 1 {
                person.health = 0
                await person.dies(game: game)
            }

        default:
            print("Unexpected rate type " + self.type)
        }
            
        
    }
}

class FlatRates: Rates {
    var rate: Float

    private enum CodingKeys: String, CodingKey {
        case rate
    }
    
    init(id: UUID = UUID(), rate: Float) {
        self.rate = rate
        
        super.init(id: id)
    }
    
    init(id: UUID = UUID(), rate: Float, type: String) {
        self.rate = rate
        super.init(id: id, type: type)
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rate = try container.decode(Float.self, forKey: .rate)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rate, forKey: .rate)
        
        try super.encode(to: encoder)
    }

    override func getRate(person: Person? = nil) -> Float {
        return self.rate
    }
    
    override func apply(person: Person, game: GameEngine) async {
        let gameDate = await game.getGameDate()
        let minD = await game.getMinDate()
        let maxD = await game.getMaxDate()
        if (self.startDate ?? minD) <= gameDate && (self.endDate ?? maxD) >= gameDate {
            switch self.type {
                //        case "Life Expectancy":
                //            if Float.random(in: 0...1) < (pow(Float(person.age()), ((self.rate + 10)/100))/self.rate) {
                //                person.dies()
                //                person.causeOfDeath = "ill health"
                //            }
                
            case "Family Size":
                if person.descendants.count >= Int(self.rate) && Float.random(in: 0...1) < (pow(0.95, (self.rate / Float(person.descendants.count)))) {
                    person.tryingForFamily = false
                    person.spouse?.tryingForFamily = false
                } else if Float.random(in: 0...1) < Float(person.descendants.count) / (self.rate * 2) {
                    person.tryingForFamily = false
                    person.spouse?.tryingForFamily = false
                }

            case "Inherit Job", "Return To Pre-Event Location", "Inter-Tribe Battle":
                return

            default:
                return
                print("Unexpected type " + self.type)
            }
        }
    }
}

class ExchangeRate: Rates {
    var rate: Float
    var buyResourceID: UUID
    var sellResourceID: UUID
    
    // Computed properties for backward compatibility
    var buyResource: Resource {
        get {
            return ConfigLoader.findResource(byID: buyResourceID)!
        }
        set {
            buyResourceID = newValue.id
        }
    }
    
    var sellResource: Resource {
        get {
            return ConfigLoader.findResource(byID: sellResourceID)!
        }
        set {
            sellResourceID = newValue.id
        }
    }

    private enum CodingKeys: String, CodingKey {
        case rate
        case buyResource
        case sellResource
    }

    init(id: UUID = UUID(), rate: Float, buyResourceID: UUID, sellResourceID: UUID) {
        self.rate = rate
        self.buyResourceID = buyResourceID
        self.sellResourceID = sellResourceID

        super.init(id: id)
        self.type = "Exchange Rate"

    }

    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rate = try container.decode(Float.self, forKey: .rate)
        let strBuyResource = try container.decode(String.self, forKey: .buyResource)
        let strSellResource = try container.decode(String.self, forKey: .sellResource)

        guard let buyResource = ConfigLoader.resources.first(where: {$0.name == strBuyResource}) else {
            throw DecodingError.dataCorruptedError(forKey: .buyResource, in: container,
                                                    debugDescription: "Resource '\(strBuyResource)' not found in ConfigLoader")
        }
        guard let sellResource = ConfigLoader.resources.first(where: {$0.name == strSellResource}) else {
            throw DecodingError.dataCorruptedError(forKey: .sellResource, in: container,
                                                    debugDescription: "Resource '\(strSellResource)' not found in ConfigLoader")
        }
        
        self.buyResourceID = buyResource.id
        self.sellResourceID = sellResource.id

        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rate, forKey: .rate)
        
        // Encode resource names instead of UUIDs
        if let buyResource = ConfigLoader.findResource(byID: buyResourceID) {
            try container.encode(buyResource.name, forKey: .buyResource)
        }
        if let sellResource = ConfigLoader.findResource(byID: sellResourceID) {
            try container.encode(sellResource.name, forKey: .sellResource)
        }
        
        try super.encode(to: encoder)
    }

}

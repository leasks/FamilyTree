//
//  Rates.swift
//  FamilyTree
//
//  Created by Stephen Leask on 31/07/2023.
//

import Foundation

struct RateAgeRanges: Decodable {
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
    var type: String
    var startDate: Date?
    var endDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case startDate
        case endDate
    }
    
    init() {
        self.type = ""
    }
    
    init(type: String) {
        self.type = type
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
    }
    
    func getRate(person: Person? = nil) -> Float { return 0 }

    func apply(person: Person, game: GameEngine) async { }
}
extension Rates: Hashable {
    static func == (lhs: Rates, rhs: Rates) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(type)
    }
}

class AgeBasedRates: Rates {
    var rates: Set<RateAgeRanges>?

    private enum CodingKeys: String, CodingKey {
        case rates
    }
    
    init(rates: Set<RateAgeRanges>) {
        self.rates = rates
        
        super.init()
    }
    
    init(rates: Set<RateAgeRanges>, type: String) {
        self.rates = rates
        super.init(type: type)
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rates = try container.decode(Set<RateAgeRanges>.self, forKey: .rates)
        
        try super.init(from: decoder)
    }

    override func getRate(person: Person? = nil) -> Float {
        if person == nil { return 0 }
        let age = person!.age
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
    
    init(rate: Float) {
        self.rate = rate
        
        super.init()
    }
    
    init(rate: Float, type: String) {
        self.rate = rate
        super.init(type: type)
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rate = try container.decode(Float.self, forKey: .rate)
        
        try super.init(from: decoder)
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
    var buyResource: Resource
    var sellResource: Resource

    private enum CodingKeys: String, CodingKey {
        case rate
        case buyResource
        case sellResource
    }

    init(rate: Float, buyResource: Resource, sellResource: Resource) {
        self.rate = rate
        self.buyResource = buyResource
        self.sellResource = sellResource

        super.init()
        self.type = "Exchange Rate"

    }

    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rate = try container.decode(Float.self, forKey: .rate)
        let strBuyResource = try container.decode(String.self, forKey: .buyResource)
        let strSellResource = try container.decode(String.self, forKey: .sellResource)

        self.buyResource = ConfigLoader.resources.first(where: {$0.name == strBuyResource})!
        self.sellResource = ConfigLoader.resources.first(where: {$0.name == strSellResource})!

        try super.init(from: decoder)
    }

}

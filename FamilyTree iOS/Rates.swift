//
//  Rates.swift
//  FamilyTree
//
//  Created by Stephen Leask on 31/07/2023.
//

import Foundation

struct RateAgeRanges: Decodable {
    var startAge: Int
    var endAge: Int
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
    var type: String = ""
    var startDate: Date?
    var endDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case startDate
        case endDate
    }
    
    init() {
        
    }
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
    }
    
    func getRate(person: Person) -> Float { return 0 }

    func apply(person: Person) { }
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
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rates = try container.decode(Set<RateAgeRanges>.self, forKey: .rates)
        
        try super.init(from: decoder)
    }

    override func getRate(person: Person) -> Float {
        let age = person.age()
        return rates?.first(where: {$0.startAge <= age && $0.endAge > age})?.rate ?? 0
    }
    
    override func apply(person: Person) {
        // TODO: This is assuming always trying for children, need to include indicator of trying influenced by number of children rate
        if self.type == "Fertility" {
            for rate in rates ?? [] {
                let age = person.age()
                if age >= rate.startAge && age <= rate.endAge {
                    if Float.random(in: 0...1) < rate.rate {
                        person.hasChild()
                    }
                }
            }
        }
    }
}

class FlatRates: Rates {
    var rate: Float?

    private enum CodingKeys: String, CodingKey {
        case rate
    }
    
    init(rate: Float) {
        self.rate = rate
        
        super.init()
    }
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rate = try container.decode(Float.self, forKey: .rate)
        
        try super.init(from: decoder)
    }

    override func getRate(person: Person) -> Float {
        return self.rate ?? 0
    }
    
    override func apply(person: Person) {
        // TODO: Lookup how swift does switch/case processing and maybe add a base/measure of what the rate is
        if self.type == "Life Expectancy" {
            if Float.random(in: 0...1) < (pow(Float(person.age()), (((self.rate ?? 0.01) + 10)/100))/(self.rate ?? 0.01)) {
                person.dies()
                person.causeOfDeath = "ill health"
            }
        }
    }
}

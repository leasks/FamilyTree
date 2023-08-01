//
//  Rates.swift
//  FamilyTree
//
//  Created by Stephen Leask on 31/07/2023.
//

import Foundation

struct RateAgeRanges {
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
    
    func getRate(person: Person) -> Float { return 0 }
    
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
    var rates: Set<RateAgeRanges> = []
    
    override func getRate(person: Person) -> Float {
        return rates.first(where: {$0.startAge <= person.age() && $0.endAge > person.age()})?.rate ?? 0
    }
}

class FlatRates: Rates {
    var rate: Float = 0.0
    
    override func getRate(person: Person) -> Float {
        return self.rate
    }
}

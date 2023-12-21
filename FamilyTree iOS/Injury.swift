//
//  Injury.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Injury: Codable {
    var name: String
    var cure: Cure?
    
    var likelihood: Float?
    var untreatedMortality: Float?
    var treatedMortality: Float?
    
    func apply(person: Person) {
        // TODO: Add treatment check and potential removal of injury when treated
        if !person.injuries.contains(self) && Float.random(in: 0...1) < self.likelihood ?? 0 {
            person.injuries.insert(self)
        }
        
        if person.injuries.contains(self) {
            if Float.random(in: 0...1) < self.untreatedMortality ?? 0 {
                person.dies()
                person.causeOfDeath = self.name
            }
        }
    }

}
extension Injury: Hashable {
    static func == (lhs: Injury, rhs: Injury) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

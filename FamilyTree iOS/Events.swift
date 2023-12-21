//
//  Events.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Event: Codable {
    var name: String
    var description: String
    var triggerYear: Int
    var triggerMonth: Int?
    var injuriesAdded: Set<Injury>? = []
    var injuriesRemoved: Set<Injury>? = []
    var affiliationsAdded: Set<Affiliation>? = []
    var affiliationsRemoved: Set<Affiliation>? = []
    var newNPC: NewNPC?
    
    func apply() {
        // Add new injuries & affiliations
        GameEngine.getInstance().availableInjuries.formUnion(self.injuriesAdded ?? [])
        GameEngine.getInstance().availableAffiliations.formUnion(self.affiliationsAdded ?? [])
        
        // Take injuries away & affiliations
        GameEngine.getInstance().availableInjuries.subtract(self.injuriesRemoved ?? [])
        GameEngine.getInstance().availableAffiliations.subtract(self.affiliationsRemoved ?? [])
        
        // Add extra NPCs if any
        if self.newNPC != nil {
            let calendar = Calendar(identifier: .gregorian)

            for _ in 1...Int.random(in: Int(Double(self.newNPC!.count) * 0.9)...Int(Double(self.newNPC!.count) * 1.1)) {
                let minAge = self.newNPC!.minAge
                let maxAge = self.newNPC!.maxAge
                let components = DateComponents(year: GameEngine.getInstance().year - Int.random(in: minAge...maxAge), month: Int.random(in: 1...12), day: Int.random(in: 1...28))
                var person: Person = Person(name: "Temp", dateOfBirth: calendar.date(from: components)!, gender: Sex.female)
                person = person.generateRandomPerson(affiliation: self.newNPC!.affiliation)
                person.affiliations = [self.newNPC!.affiliation]
                person.dateOfBirth = calendar.date(from: components)!

                GameEngine.getInstance().persons.insert(person)

            }
        }
    }
}
extension Event: Hashable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.name == rhs.name && lhs.triggerYear == rhs.triggerYear
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(triggerYear)
    }
}

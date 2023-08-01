//
//  File.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

enum Sex {
    case male
    case female
}

struct Name: Codable {
    let name: String
    let gender: String
    let startDate: Date?
    let endDate: Date?
}
extension Name: Hashable {
    static func == (lhs: Name, rhs: Name) -> Bool {
        return lhs.name == rhs.name && lhs.gender == rhs.gender && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(gender)
        hasher.combine(startDate)
        hasher.combine(endDate)
    }
}


class Person {
    var name: String
    var dateOfBirth: Date
    var dateOfDeath: Date?
    var dateOfMarriage: Date?
    var money: Money?
    var gender: Sex
    var affiliations: Set<Affiliation> = []
    var location: Location
    var injuries: Set<Injury> = []
    var job: Job?
    var spouse: Person?
    var descendants: Set<Person> = []

    init(name: String, dateOfBirth: Date, gender: Sex, location: Location) {
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.location = location
    }

    func dies() {
        // Set date of death
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: GameEngine.getInstance().year, month: GameEngine.getInstance().month)
        self.dateOfDeath = calendar.date(from: components)

        // If no descendants then the game is over
        if descendants.isEmpty {
            GameEngine.getInstance().endGame()
        }
    }

    func hasChild(child: Person) {
        self.descendants.insert(child)

        // And add child to spouse
        self.spouse?.descendants.insert(child)

        if GameEngine.getInstance().tree.contains(where: {$0.value.contains(self)}) {
            // Need to add to/update the tree as well
            GameEngine.getInstance().tree[GameEngine.getInstance().tree.first(where: {$0.value.contains(self)})!.key + 1] = self.descendants
        }
    }

    func marries(spouse: Person) {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: GameEngine.getInstance().year, month: GameEngine.getInstance().month)

        self.spouse = spouse
        self.dateOfMarriage = calendar.date(from: components)
        spouse.spouse = self
        spouse.dateOfMarriage = calendar.date(from: components)

        // Add to tree if needed
        if GameEngine.getInstance().getActivePerson() == self {
            GameEngine.getInstance().tree[GameEngine.getInstance().generation]?.insert(spouse)
        } else if GameEngine.getInstance().getActivePerson() == spouse {
            GameEngine.getInstance().tree[GameEngine.getInstance().generation]?.insert(self)
        }
    }
    
    func age() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: GameEngine.getInstance().year, month: GameEngine.getInstance().month)
        let currDate = calendar.date(from: components)!
        let personAge = calendar.dateComponents([.year], from: self.dateOfBirth, to: currDate).year ?? 0
        return personAge
    }
}

extension Person: Hashable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.name == rhs.name && lhs.dateOfBirth == rhs.dateOfBirth && lhs.gender == rhs.gender
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(dateOfBirth)
        hasher.combine(gender)
    }
}

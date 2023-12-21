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

struct NewNPC: Codable {
    let count: Int
    let minAge: Int
    let maxAge: Int
    let affiliation: Affiliation
}

struct Name: Codable {
    let name: String
    let gender: String
    let startDate: Date?
    let endDate: Date?
    let affiliation: Affiliation?
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
    var causeOfDeath: String?
    var dateOfMarriage: Date?
    var money: Money?
    var gender: Sex
    var affiliations: Set<Affiliation> = []
    var location: Location?
    var injuries: Set<Injury> = []
    var job: Job?
    var spouse: Person?
    var descendants: Set<Person> = []

    init(name: String, dateOfBirth: Date, gender: Sex) {
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.gender = gender
    }

    func dies() {
        // Set date of death
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: GameEngine.getInstance().year, month: Int.random(in: 1...12), day: Int.random(in: 1...28))
        self.dateOfDeath = calendar.date(from: components)

        // If no descendants then the game is over
        if descendants.isEmpty {
            GameEngine.getInstance().endGame()
        }
    }

    func generateName(filter: Set<Name>) -> Name {
        if Bool.random() {
            return filter.filter({$0.gender == "female"}).randomElement()!
        } else {
            return filter.filter({$0.gender == "male"}).randomElement()!
        }
    }
    
    func generateRandomPerson(affiliation: Affiliation) -> Person {
        let calendar = Calendar(identifier: .gregorian)
        let name: Name
        let maxD = GameEngine.getInstance().getMaxDate()
        let minD = GameEngine.getInstance().getMinDate()
        let gameD = GameEngine.getInstance().getGameDate()
        let affils = GameEngine.getInstance().availableAffiliations
        var filter = GameEngine.getInstance().names.filter({$0.endDate ?? maxD > gameD})
        filter = filter.filter({$0.startDate ?? minD < gameD})
        filter = filter.filter({
            if $0.affiliation == nil {
                return true
            } else if !affils.contains($0.affiliation!) {
                return true
            } else {
                return affiliation == $0.affiliation!
            }
        })
        name = generateName(filter: filter)
        
        // Use game date -1 to indicate child born in the last year
        let components = DateComponents(year: GameEngine.getInstance().year - 1, month: Int.random(in: 1...12), day: Int.random(in: 1...28))

        return Person(name: name.name, dateOfBirth: calendar.date(from: components)!, gender: name.gender == "male" ? Sex.male : Sex.female)
    }
    
    func generateRandomPerson(parent: Person) -> Person {
        let calendar = Calendar(identifier: .gregorian)
        let name: Name
        let maxD = GameEngine.getInstance().getMaxDate()
        let minD = GameEngine.getInstance().getMinDate()
        let gameD = GameEngine.getInstance().getGameDate()
        let affils = GameEngine.getInstance().availableAffiliations
        var filter = GameEngine.getInstance().names.filter({$0.endDate ?? maxD > gameD})
        filter = filter.filter({$0.startDate ?? minD < gameD})
        filter = filter.filter({
            if parent.affiliations.count == 0 {
                return true
            } else if $0.affiliation == nil {
                return true
            } else if parent.affiliations.isDisjoint(with: affils) {
                return true
            } else {
                return parent.affiliations.contains($0.affiliation!)
            }
        })
        name = generateName(filter: filter)
        
        // Use game date -1 to indicate child born in the last year
        let components = DateComponents(year: GameEngine.getInstance().year - 1, month: Int.random(in: 1...12), day: Int.random(in: 1...28))

        return Person(name: name.name, dateOfBirth: calendar.date(from: components)!, gender: name.gender == "male" ? Sex.male : Sex.female)
    }
    
    func generateRandomPerson() -> Person {
        let calendar = Calendar(identifier: .gregorian)
        let name: Name
        let maxD = GameEngine.getInstance().getMaxDate()
        let minD = GameEngine.getInstance().getMinDate()
        let gameD = GameEngine.getInstance().getGameDate()
        var filter = GameEngine.getInstance().names.filter({$0.endDate ?? maxD > gameD})
        filter = filter.filter({$0.startDate ?? minD < gameD})
        name = generateName(filter: filter)
        
        // Use game date -1 to indicate child born in the last year
        let components = DateComponents(year: GameEngine.getInstance().year - 1, month: Int.random(in: 1...12), day: Int.random(in: 1...28))

        return Person(name: name.name, dateOfBirth: calendar.date(from: components)!, gender: name.gender == "male" ? Sex.male : Sex.female)
    }
    
    func hasChild() {
        if self.gender == Sex.male { return }  // As of today males cannot have children
        
        let child = generateRandomPerson(parent: self)
        
        self.hasChild(child: child)
        
        // Add as a NPC
        GameEngine.getInstance().persons.insert(child)
    }
    
    func hasChild(child: Person) {
        // Children inherit characteristics such as location
        child.location = self.location
        child.affiliations = self.affiliations
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
        let deathDate = self.dateOfDeath ?? GameEngine.getInstance().getMaxDate()
        let personAge = currDate < deathDate ?
        calendar.dateComponents([.year], from: self.dateOfBirth, to: currDate).year ?? 0 :
        calendar.dateComponents([.year], from: self.dateOfBirth, to: deathDate).year ?? 0
        return personAge
    }
    
    func asString() -> String {
        var retString = self.name
        if self.affiliations.first != nil {
            retString += " (\(self.affiliations.first!.name))"
        }
        retString += " born on \(self.dateOfBirth.description)"
        if self.dateOfDeath == nil {
            retString += " and is currently \(self.age()) years old"
        } else {
            retString += " lived until \(self.dateOfDeath!.description)"
            retString += " dying at the age of \(self.age()) years old"
            retString += " due to \(self.causeOfDeath!)"
        }
        
        if self.descendants.count > 0 {
            retString += " and has \(self.descendants.count) children"
        }
        
        return retString
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

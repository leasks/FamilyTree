//
//  Resource.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 27/08/2023.
//

import Foundation

class Resource: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case inheritable
        case lifespan
        case requiredResources
    }

    let name: String
    var inheritable: Bool = true
    var forSale: Bool = false
    var matchedBuyer: Person?
    var lifespan: Int = 0
    var age: Int = 0
    var requiredResources: [Resource: Int] = [:]

    init(name: String) {
        self.name = name
    }
    
    func markForSale() {
        forSale = true
    }
    
    func setMatchedBuyer(_ person: Person) {
        matchedBuyer = person
    }

    func getExchRate() -> ExchangeRate? {
        for rate in ConfigLoader.rates.filter({$0 is ExchangeRate}) {
            let exchRate = rate as? ExchangeRate
            if exchRate?.buyResource.name == self.name {
//                if self.matchedBuyer?.resources[exchRate!.sellResource] ?? 0 >= Int(exchRate?.rate ?? 0) {
                    return exchRate
//                }
            }
        }

        return nil
    }

    func newInstance() -> Resource {
        let retVal = Resource(name: self.name)
        retVal.lifespan = self.lifespan
        return retVal
    }

    func countIgnoringAge(resources: [Resource: Int]) -> Int {
        var total = 0

        for (res, count) in resources where res.name == self.name {
            total += count
        }

        return total
    }

    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.inheritable = try container.decodeIfPresent(Bool.self, forKey: .inheritable) ?? true
        self.lifespan = try container.decodeIfPresent(Int.self, forKey: .lifespan) ?? 0
        self.forSale = false
        self.age = 0
        self.requiredResources = [:]

        if !ConfigLoader.resources.isEmpty {
            var reqResources = try container.decodeIfPresent([String: Int].self, forKey: .requiredResources)
            for (resString, count) in reqResources ?? [:] {
                let res = ConfigLoader.resources.filter({$0.name == resString}).first!
                self.requiredResources[res] = count
            }
        }
    }

    func findBuyers(game: GameEngine) async -> Set<Person> {
        var retList: Set<Person> = []

        for person in await game.persons.shuffled() where countIgnoringAge(resources: person.wantedResources) > 0 {
            retList.insert(person)
            if retList.count > 3 { break }
        }
        return retList
    }

    func createResource(person: Person) {
        var canCreate: Bool = true
        for (resource, count) in requiredResources where resource.countIgnoringAge(resources: person.resources) < count {
            // Do not have sufficient of a resource
            person.wantsToBuy(resource: resource, number: count - resource.countIgnoringAge(resources: person.resources))
            canCreate = false
        }

        if canCreate {
            // Had enough of the required resources so I can make the resource
            let newResource = newInstance()
            newResource.forSale = true
            person.addResource(resource: newResource)

            for (resource, _) in requiredResources {
                person.removeResource(resource: resource)
            }
        }
    }

}
extension Resource: Hashable {
    static func == (lhs: Resource, rhs: Resource) -> Bool {
        return lhs.name == rhs.name && lhs.age == rhs.age && lhs.forSale == rhs.forSale
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(age)
        hasher.combine(forSale)
    }
}

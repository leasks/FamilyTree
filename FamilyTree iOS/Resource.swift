//
//  Resource.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 27/08/2023.
//

import Foundation

class Resource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case inheritable
        case lifespan
        case requiredResourceIDs
    }

    let id: UUID
    let name: String
    var inheritable: Bool = true
    var forSale: Bool = false
    var matchedBuyer: Person?
    var lifespan: Int = 0
    var age: Int = 0
    var requiredResourceIDs: [UUID: Int] = [:]
    
    // Computed property for backward compatibility
    var requiredResources: [Resource: Int] {
        get {
            var result: [Resource: Int] = [:]
            for (id, count) in requiredResourceIDs {
                if let resource = ConfigLoader.findResource(byID: id) {
                    result[resource] = count
                }
            }
            return result
        }
        set {
            requiredResourceIDs = [:]
            for (resource, count) in newValue {
                requiredResourceIDs[resource.id] = count
            }
        }
    }

    init(id: UUID = UUID(), name: String) {
        self.id = id
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
        let retVal = Resource(id: UUID(), name: self.name)
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
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.inheritable = try container.decodeIfPresent(Bool.self, forKey: .inheritable) ?? true
        self.lifespan = try container.decodeIfPresent(Int.self, forKey: .lifespan) ?? 0
        self.forSale = false
        self.age = 0
        self.requiredResourceIDs = [:]

        if !ConfigLoader.resources.isEmpty {
            let reqResources = try container.decodeIfPresent([String: Int].self, forKey: .requiredResourceIDs)
            for (resString, count) in reqResources ?? [:] {
                if let res = ConfigLoader.resources.filter({$0.name == resString}).first {
                    self.requiredResourceIDs[res.id] = count
                } else {
                    print("Warning: Required resource '\(resString)' not found in ConfigLoader for resource '\(self.name)'")
                }
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
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

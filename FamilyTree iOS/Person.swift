//
//  File.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

enum Sex: String, Codable {
    case male
    case female
}

struct NewNPC: Codable {
    private enum CodingKeys: String, CodingKey {
        case count
        case minAge
        case maxAge
        case affiliationID
        case jobDistribution
        case genderDistribution
    }

    let count: Int
    let minAge: Int
    let maxAge: Int
    let affiliationID: UUID?
    let jobDistribution: [String: Float]
    var genderDistribution: [Sex: Float]?
    
    // Computed property for backward compatibility
    var affiliation: Affiliation? {
        get {
            guard let id = affiliationID else { return nil }
            return ConfigLoader.findAffiliation(byID: id)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decode(Int.self, forKey: .count)
        self.minAge = try container.decode(Int.self, forKey: .minAge)
        self.maxAge = try container.decode(Int.self, forKey: .maxAge)
        self.jobDistribution = try container.decode([String: Float].self, forKey: .jobDistribution)
        self.genderDistribution = try container.decodeIfPresent([Sex: Float].self, forKey: .genderDistribution)

        // Look up the affilliations through its name from the ConfigLoader
        let strAffil = try container.decodeIfPresent(String.self, forKey: .affiliationID)
        guard let affiliation = ConfigLoader.affiliations.first(where: {$0.name == strAffil}) else {
            throw DecodingError.dataCorruptedError(forKey: .affiliationID, in: container,
                                                    debugDescription: "Affiliation '\(strAffil ?? "nil")' not found in ConfigLoader")
        }
        self.affiliationID = affiliation.id
    }

    init (count: Int, minAge: Int, maxAge: Int, affiliationID: UUID? = nil, jobDistribution: [String: Float]? = [:], genderDistribution: [Sex: Float]? = [:]) {
        self.count = count
        self.minAge = minAge
        self.maxAge = maxAge
        self.genderDistribution = genderDistribution
        self.jobDistribution = jobDistribution ?? [:]
        self.affiliationID = affiliationID
    }
}

struct Name: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case gender
        case affiliationIDs
    }

    let id: UUID
    let name: String
    let gender: Sex
    let affiliationIDs: Set<UUID>?
    
    // Computed property for backward compatibility
    var affiliation: Set<Affiliation>? {
        get {
            guard let ids = affiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.gender = try container.decode(Sex.self, forKey: .gender)

        // Look up the affilliations through its name from the ConfigLoader
        let strAffil = try container.decodeIfPresent([String].self, forKey: .affiliationIDs)
        var nameAfilIDs: Set<UUID> = []
        for afil in strAffil ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                nameAfilIDs.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for name '\(self.name)'")
            }
        }
        self.affiliationIDs = nameAfilIDs
    }
    
    init(id: UUID = UUID(), name: String, gender: Sex, affiliationIDs: Set<UUID>? = nil) {
        self.id = id
        self.name = name
        self.gender = gender
        self.affiliationIDs = affiliationIDs
    }

}
extension Name: Hashable {
    static func == (lhs: Name, rhs: Name) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


final class Person: Codable, @unchecked Sendable { //swiftlint:disable:this type_body_length
    // TODO: Refactor to move strings for events and/or string displays elsewhere
    let id: UUID
    var name: String
    var dateOfBirth: Date
    var age: Int
    var isThePlayer: Bool = false
    var relatedToThePlayer: Bool = false
    var dateOfDeath: Date?
    var causeOfDeath: String?
    var dateOfMarriage: Date?
    var money: Money?
    var gender: Sex
    var affiliationIDs: Set<UUID> = []
    var locationID: UUID?
    var injuryIDs: Set<UUID> = []
    var treatedInjuryIDs: Set<UUID> = []
    var jobID: UUID?
    var jobStartDate: Date?
    var skillIDs: Set<UUID>? = []
    var spouseID: UUID?
    var descendantIDs: Set<UUID> = []
    var tryingForFamily: Bool = true
    var resourceIDs: [UUID: Int] = [:]
    var wantedResourceIDs: [UUID: Int] = [:]
    var familyBusiness: JobType = .general
    var health: Float = 1
    
    // Direct object references (for backward compatibility and performance)
    // These should be kept in sync with the ID fields
    var _spouse: Person?
    var _descendants: Set<Person> = []
    
    // Computed properties for backward compatibility
    var affiliations: Set<Affiliation> {
        get {
            return Set(affiliationIDs.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            affiliationIDs = Set(newValue.map { $0.id })
        }
    }
    
    var location: Town? {
        get {
            guard let id = locationID else { return nil }
            return ConfigLoader.findLocation(byID: id) as? Town
        }
        set {
            locationID = newValue?.id
        }
    }
    
    var injuries: Set<Injury> {
        get {
            return Set(injuryIDs.compactMap { ConfigLoader.findInjury(byID: $0) })
        }
        set {
            injuryIDs = Set(newValue.map { $0.id })
        }
    }
    
    var treatedInjuries: Set<Injury> {
        get {
            return Set(treatedInjuryIDs.compactMap { ConfigLoader.findInjury(byID: $0) })
        }
        set {
            treatedInjuryIDs = Set(newValue.map { $0.id })
        }
    }
    
    var job: Job? {
        get {
            guard let id = jobID else { return nil }
            return ConfigLoader.findJob(byID: id)
        }
        set {
            jobID = newValue?.id
        }
    }
    
    var skills: Set<Skill>? {
        get {
            guard let ids = skillIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findSkill(byID: $0) })
        }
        set {
            skillIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var spouse: Person? {
        get {
            return _spouse
        }
        set {
            _spouse = newValue
            spouseID = newValue?.id
        }
    }
    
    var descendants: Set<Person> {
        get {
            return _descendants
        }
        set {
            _descendants = newValue
            descendantIDs = Set(newValue.map { $0.id })
        }
    }
    
    var resources: [Resource: Int] {
        get {
            var result: [Resource: Int] = [:]
            for (id, count) in resourceIDs {
                if let resource = ConfigLoader.findResource(byID: id) {
                    result[resource] = count
                }
            }
            return result
        }
        set {
            resourceIDs = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.id, $0.value) })
        }
    }
    
    var wantedResources: [Resource: Int] {
        get {
            var result: [Resource: Int] = [:]
            for (id, count) in wantedResourceIDs {
                if let resource = ConfigLoader.findResource(byID: id) {
                    result[resource] = count
                }
            }
            return result
        }
        set {
            wantedResourceIDs = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.id, $0.value) })
        }
    }

    init(name: String, dateOfBirth: Date, gender: Sex, game: GameEngine) async {
        self.id = UUID()
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.gender = gender

        let calendar = Calendar(identifier: .gregorian)
        self.age = calendar.dateComponents([.year], from: self.dateOfBirth, to: await game.getGameDate()).year ?? 0

        await game.addPerson(person: self)
    }

    func socialClass(date: Date) -> SocialClass? {
        return ConfigLoader.socialClasses.filter({$0.startDate < date})
            .filter({$0.endDate > date})
            .filter({$0.wealth <= self.wealth()})
            .filter({$0.affiliations?.isSubset(of: self.affiliations) ?? true})
            .sorted(by: {
                if $0.wealth != $1.wealth {
                    return $0.wealth > $1.wealth
                }
                // When wealth is equal, prefer classes with affiliation requirements
                let has0Affil = !($0.affiliations?.isEmpty ?? true)
                let has1Affil = !($1.affiliations?.isEmpty ?? true)
                if has0Affil != has1Affil {
                    return has0Affil
                }
                // Otherwise maintain original order
                return false
            }).first
    }

    func wealth(recursed: Bool = false) -> Float {
        var wealth: Float = 0
        for (resource, count) in resources {
            if resource.name == "Coin" {
                wealth += Float(count)
            } else {
                for exchRate in ConfigLoader.rates.filter({$0 is ExchangeRate}) {
                    if let conversion = exchRate as? ExchangeRate,
                       conversion.sellResource.name == "Coin" && conversion.buyResource == resource {
                        wealth += (conversion.rate * Float(count))
                    }
                }
            }
        }

        // Wealth is shared so if there is a spouse add their wealth
        if let spouse = spouse, !recursed {
            wealth += spouse.wealth(recursed: true)
        }
        return wealth
    }

    func treatInjuries() {
        for injury in injuries where injury.cure?.location == self.location {
            self.treatedInjuries.insert(injury)
            self.injuries.remove(injury)
        }
    }

    func addEvent(title: String, description: String, game: GameEngine) async {
        let event = await Event(name: title, description: description, triggerYear: game.year)
        await game.addActiveEvent(event)
    }

    func addInjuryEvent(injury: Injury, game: GameEngine) async {
        if injury.untreatedMortality?.getRate(person: self) ?? 0 == 1 { return } // Died from the injury so no point displaying it
        

        var desc = injury.name + "\r\n"
        desc += (injury.description ?? "") + "\r\n"
        desc += "There is a " + String((injury.untreatedMortality?.getRate(person: self) ?? 0) * 100)
        desc += "% chance of death if untreated\r\n"
        
        if let injuryCure = injury.cure {
            desc += "Can be cured at " + (injuryCure.location?.name ?? "UNSPECIFIED")
            desc += ".  Which will reduce the change of death to " + String((injury.treatedMortality?.getRate(person: self) ?? 0) * 100)
            desc += "%\r\n"
        }

        await addEvent(title: "New Illness/Injury", description: desc, game: game)
    }
    
    func addMarriageEvent(other: Person, game: GameEngine) async {

        var desc = other.name + " would like to marry\r\n"
        desc += "They are " + String(other.age) + " years old"
        if let job = other.job {
            desc += " and a " + job.name
        }
        desc += "\r\nDo you accept the proposal?"
        
        await addEvent(title: "Marriage", description: desc, game: game)
    }
    
    func addChildEvent(child: Person, game: GameEngine) async {
        var desc = child.name + " a new-born baby "
        desc += child.gender == Sex.female ? "girl" : "boy"
        desc += " is welcomed to the world"
        
        await addEvent(title: "New Child", description: desc, game: game)
    }
    
    func addFamilyDeathEvent(person: Person, game: GameEngine) async {
        var desc = person.name + " , your "
        desc += self.spouse == person ? "partner" : "child"
        desc += ", has died of " + (person.causeOfDeath ?? "unknown causes")
        desc += " at the age of " + String(person.age) + " years old"
        await addEvent(title: "Family Death", description: desc, game: game)

    }
    
    func addLearnSkillEvent(skill: Skill, game: GameEngine) async {
        if !isThePlayer { return }
        var desc = skill.name + " has been learnt"
        
        await addEvent(title: "New Skill", description: desc, game: game)
    }
    
    func addResource(resource: Resource) {
        if let currentCount = self.resources[resource] {
            self.resources[resource] = currentCount + 1
        } else {
            self.resources[resource] = 1
        }

        if let wantedCount = self.wantedResources[resource] {
            self.wantedResources[resource] = wantedCount - 1
        }

    }

    func removeResource(resource: Resource) {
        for res in self.resources.keys.filter({$0.name == resource.name}).sorted(by: {$0.age > $1.age})
        where (self.resources[res] ?? 0) > 0 {
            if let currentCount = self.resources[res] {
                self.resources[res] = currentCount - 1
                
                if currentCount - 1 == 0 {
                    self.resources.removeValue(forKey: res)
                }
            }
            return
        }
    }

    func wantsToBuy(resource: Resource, number: Int) {
        let wantedRes = resource.newInstance()
        if let currentWanted = self.wantedResources[wantedRes] {
            self.wantedResources[wantedRes] = currentWanted + number
        } else {
            self.wantedResources[wantedRes] = number
        }
    }
    
    func consumeFoodAndCheckStarvation(game: GameEngine) async {
        // Check if this person is already part of someone else's family processing
        // If they have parents who are alive and have them as descendants, skip
        if let parent = await game.persons.first(where: { person in
            person.descendants.contains(self) && person.dateOfDeath == nil
        }) {
            // This person is a child and will be processed by their parent
            return
        }
        
        // Skip if this person is a spouse and their partner will handle it
        // Use a stable ordering based on name comparison to ensure consistency
        if let spouseRef = spouse {
            // Use alphabetical ordering to determine which spouse processes the family
            if self.name > spouseRef.name {
                return
            }
        }
        
        // Single person with no family - check their own food
        if spouse == nil && descendants.isEmpty {
            await consumeFoodForPerson(game: game)
            return
        }
        
        // Process family food consumption
        var familyMembers: [Person] = []
        
        // Add children first (sorted youngest to oldest for prioritization)
        let aliveChildren = descendants.filter { $0.dateOfDeath == nil }
        let sortedChildren = aliveChildren.sorted { $0.age < $1.age }
        familyMembers.append(contentsOf: sortedChildren)
        
        // Then add adults (self first, then spouse)
        familyMembers.append(self)
        if let spouseRef = spouse {
            familyMembers.append(spouseRef)
        }
        
        // Create food resource once for efficiency
        let food = Resource(name: "Food")
        
        // Count total available food from both spouses
        var selfFoodCount = food.countIgnoringAge(resources: self.resources)
        var spouseFoodCount = spouse != nil ? food.countIgnoringAge(resources: spouse!.resources) : 0
        var availableFood = selfFoodCount + spouseFoodCount
        
        // Distribute food: children first (youngest to oldest), then adults
        for person in familyMembers {
            if availableFood > 0 {
                // Remove starvation if they have food
                if let starvation = await game.availableInjuries.first(where: { $0.name == "Starvation" }) {
                    person.injuries.remove(starvation)
                }
                availableFood -= 1
            } else {
                // Apply starvation
                await applyStarvationTo(person: person, game: game)
            }
        }
        
        // Remove all consumed food from family resources
        // Use the counts we already calculated
        for _ in 0..<selfFoodCount {
            self.removeResource(resource: food)
        }
        if let spouseRef = spouse {
            for _ in 0..<spouseFoodCount {
                spouseRef.removeResource(resource: food)
            }
        }
    }
    
    private func consumeFoodForPerson(game: GameEngine) async {
        let food = Resource(name: "Food")
        let hasFood = food.countIgnoringAge(resources: self.resources) > 0
        
        if hasFood {
            // Remove starvation if they have food
            if let starvation = await game.availableInjuries.first(where: { $0.name == "Starvation" }) {
                self.injuries.remove(starvation)
            }
            self.removeResource(resource: food)
        } else {
            // Apply starvation
            await applyStarvationTo(person: self, game: game)
        }
    }
    
    private func applyStarvationTo(person: Person, game: GameEngine) async {
        if let starvation = await game.availableInjuries.first(where: { $0.name == "Starvation" }) {
            if !person.injuries.contains(starvation) {
                person.injuries.insert(starvation)
                // Decrease health when starvation is applied
                person.health = max(0, person.health - 0.1)
            }
        }
    }
    

    func marries(game: GameEngine, minAge: Int = 0, locationFilter: LocationType? = .town) async {
        // Select a random spouse for this person who is not already married
        guard self.dateOfMarriage == nil || self.spouse?.dateOfDeath != nil else { return } // Only remarry if spouse is dead

        var filter = await game.persons.filter({$0.dateOfMarriage == nil})
        filter = filter.filter({$0.dateOfDeath == nil})
        filter = filter.filter({$0.age > minAge})

        if self.gender == Sex.female {
            filter = filter.filter({$0.gender == .male})
        } else {
            filter = filter.filter({$0.gender == .female})
        }
        
        // Check for any incompatible affiliations
        for affiliation in affiliations {
            if let dislikedAffiliations = affiliation.dislikedAffiliations {
                filter = filter.filter({ dislikedAffiliations.isDisjoint(with: $0.affiliations) })
            }
        }

        // Check for any social class incompatibility
        let rate = ConfigLoader.rates.filter({$0.type == "Class Mixing"}).first?.getRate()
        let gameD = await game.getGameDate()
        if Float.random(in: 0...1) < rate ?? 1 {
            filter = filter.filter({$0.socialClass(date: gameD) == self.socialClass(date: gameD)})
        }
        
        // TODO: Remove any children, siblings and parents!  Creating BAD MEMORY ACCESS
//        let person = await game.persons.first(where: {$0 == self})!
//        filter = filter.filter({!person.descendants.contains($0)})
//        filter = filter.filter({!$0.descendants.contains(person)})
//        filter = filter.filter({person.descendants.isDisjoint(with: $0.descendants)})

        // Filter to any location filters
        // TODO: Make apply the type details in to the filter
        if locationFilter != nil {
            filter = filter.filter({$0.location == self.location})
        }

        // Filter the ages to be with a set range of each other
        // TODO: This is hardcoded to 10 but make more dynamic
        let personAge = self.age
        let ageGap = Int.random(in: 1...10)
        filter = filter.filter({$0.age > personAge - ageGap}).filter({$0.age < personAge + ageGap})

        if filter.count > 0 {
            guard let spouse = filter.randomElement() else { return }
            self.marries(spouse: spouse, game: game)
            if await game.getActivePerson() == self {
                if let actualSpouse = self.spouse {
                    await self.addMarriageEvent(other: actualSpouse, game: game)
                }
            }
        }
    }
    
    func dies(game: GameEngine, fairInheritance: Bool = false) async {
        // Set date of death
        self.dateOfDeath = await game.generateDate(year: game.year)
                
        // Perform any inheritance of resources
        for resource in self.resources.keys where resource.inheritable {
            if fairInheritance, let spouse = self.spouse, spouse.dateOfDeath == nil {
                while self.resources[resource] ?? 0 > 0 {
                    spouse.addResource(resource: resource)
                    self.removeResource(resource: resource)
                }
            }
            
            let numChild = self.descendants.filter({$0.dateOfDeath == nil}).count

            if numChild > 0 {
                while self.resources[resource] ?? 0 > 0 {
                    for child in self.descendants.filter({$0.dateOfDeath == nil}).sorted(by: {
                        if $0.gender == $1.gender {
                            return $0.age > $1.age
                        } else {
                            return $0.gender == .male
                        }
                    })
                    where self.resources[resource] ?? 0 > 0 {
                        // Check if it's really needed
                        let jobs = await game.availableJobs.filter({
                            ($0.requiredResources?.contains(resource) ?? false)
                            && ($0.requiredSkills?.isSubset(of: (child.job?.learnSkills ?? [:]).keys) ?? false)
                        })

                        if jobs.isEmpty {
                            resource.forSale = true
                        }

                        child.addResource(resource: resource)
                        self.removeResource(resource: resource)
                        await child.upgradeJob(resource: resource, game: game)  // Have a new resource so maybe can get a better job

                        if !fairInheritance { break }
                    }
                }
            }
        }

        // If no descendants then the game is over
        if descendants.filter({$0.dateOfDeath == nil}).isEmpty && isThePlayer {
            await game.endGame()
        }
    }
    
    func generateName(filter: Set<Name>) -> Name {
        if Bool.random() {
            return filter.filter({$0.gender == .female}).randomElement()!
        } else {
            return filter.filter({$0.gender == .male}).randomElement()!
        }
    }
    
    func generateRandomPerson(affiliation: Affiliation, gender: Sex, age: Int, game: GameEngine) async -> Person {
        let name: Name
        let affils = await game.availableAffiliations
        var filter = ConfigLoader.names
        filter = filter.filter({
            if $0.affiliation == nil {
                return true
            } else if let affiliation = $0.affiliation, !affils.isDisjoint(with: affiliation) {
                return true
            } else if let affiliation = $0.affiliation {
                return affiliation.contains(affiliation)
            } else {
                return false
            }
        })
        if gender == .male {
            filter = filter.filter({$0.gender == .male})
        } else {
            filter = filter.filter({$0.gender == .female})
        }
        let rand = ConfigLoader.names.randomElement() ?? Name(name: "Unknown", gender: gender, affiliation: nil)
        name = filter.randomElement() ?? rand
        
        // Use game date -1 to indicate child born in the last year
        let person = await Person(name: name.name, dateOfBirth: game.generateDate(year: game.year - age), gender: name.gender, game: game)
        person.affiliations.insert(affiliation)

        if let capital = affiliation.capital {
            person.location = capital
        }
        return person
    }
    
    func generateRandomPerson(parents: Set<Person>, patriachy: Bool = true, game: GameEngine) async -> Person {
        let name: Name
        let affils = await game.availableAffiliations
        var parentAffils: Set<Affiliation> = []
        for parent in parents {
            parentAffils.formUnion(parent.affiliations)
        }
        
        var filter = ConfigLoader.names
        filter = filter.filter({
            if parentAffils.count == 0 {
                return true
            } else if $0.affiliation == nil {
                return true
            } else if parentAffils.isDisjoint(with: affils) {
                return true
            } else {
                for parentAffil in parentAffils {
                    if let nameAffiliation = $0.affiliation, nameAffiliation.contains(parentAffil) {
                        return true
                    }
                }
                return false
            }
        })
        if filter.count == 0 {
            filter = ConfigLoader.names
        }
        name = generateName(filter: filter)
        
        // Use game date -1 to indicate child born in the last year
        let person =  await Person(name: name.name, dateOfBirth: game.generateDate(year: game.year - 1), gender: name.gender, game: game)
        if patriachy {
            // Only take the male heritage
            for parent in parents where parent.gender == Sex.male {
                person.affiliations = parent.affiliations
            }
        } else {
            person.affiliations = parentAffils
        }

        // Locate person where the parents are
        if let parentLocation = parents.first?.location {
            person.location = parentLocation
        }
        return person
    }
    
    func hasChild(game: GameEngine, patriachy: Bool = true) async {
        if self.gender == Sex.male { return }  // As of today males cannot have children
        
        guard let spouse = self.spouse else { return }  // Not married so cannot have children TODO: Switch to relationship rather than marriage?
        
        if spouse.dateOfDeath != nil { return } // Spouse is dead so again cannot have children
        
        if !self.tryingForFamily { return } // No longer trying
        
        let child = await generateRandomPerson(parents: [self, spouse], patriachy: patriachy, game: game)
        
        await self.hasChild(child: child, game: game)
        
        // TODO: Is this needed Add as a NPC
        //await game.addPerson(person: child)
    }
    
    func hasChild(child: Person, game: GameEngine) async {
        // Children inherit characteristics such as location and relation to the player
        child.relatedToThePlayer = self.relatedToThePlayer ? true : (self.spouse?.relatedToThePlayer ?? false)
        child.location = self.location
        if let job = job {
            child.familyBusiness = job.type ?? .general
        }

        self.descendants.insert(child)
        
        // And add child to spouse
        self.spouse?.descendants.insert(child)

        if isThePlayer {
            await self.addChildEvent(child: child, game: game)
        } else if self.spouse?.isThePlayer ?? false {
            await self.spouse?.addChildEvent(child: child, game: game)
        }


    }
    
    func marries(spouse: Person, game: GameEngine) {
        self.spouse = spouse
        Task {
            self.dateOfMarriage = await game.generateDate(year: game.year)
        }
        spouse.spouse = self
        spouse.dateOfMarriage = self.dateOfMarriage

        // Gain affiliations - TODO: Limit this to only shareable one?
        self.affiliations.formUnion(spouse.affiliations)
        spouse.affiliations.formUnion(self.affiliations)
    }
    
    func seekJob(startDate: Date, game: GameEngine) async {
        let gameD = await game.getGameDate()
        var jobFilter = await game.availableJobs.filter({$0.meetsRequirements(person: self, gameDate: gameD)})

        let minD = await game.getMinDate()
        let maxD = await game.getMaxDate()
        let followFootsteps = ConfigLoader.rates.first(where: {$0.type == "Inherit Job" && $0.startDate ?? minD < gameD && $0.endDate ?? maxD > gameD})
        if Float.random(in: 0...1) < followFootsteps?.getRate(person: self) ?? 0 {
            jobFilter = jobFilter.filter({$0.type == self.familyBusiness})
        }

        if jobFilter.count > 0 {
            let potentialJob = jobFilter.randomElement()
            if let maxCount = potentialJob?.maxCount, maxCount > 0 {
                let currCount = await game.persons.filter({!$0.affiliations.isDisjoint(with: self.affiliations)
                    && $0.job == potentialJob
                    && $0.dateOfDeath == nil
                }).count
                if currCount >= maxCount {
                    // Position is already filled
                    return
                }
            }
            self.job = potentialJob
            self.jobStartDate = startDate
            if let earnAffiliations = self.job?.earnAffiliations {
                self.affiliations.formUnion(earnAffiliations)
            }
            
        }
    }

    func upgradeJob(skill: Skill? = nil, resource: Resource? = nil, game: GameEngine) async {
        let gameD = await game.getGameDate()
        var jobFilter = await game.availableJobs.filter({$0.meetsRequirements(person: self, gameDate: gameD)})
        jobFilter = jobFilter.filter({$0.allowedGenders.contains(self.gender)})
        if self.affiliations.count > 0 {
            jobFilter = jobFilter.filter({self.affiliations.intersection($0.affiliations ?? []).count > 0})
        } else {
            jobFilter = jobFilter.filter({($0.affiliations ?? []).count == 0})
        }
        if let skill = skill {
            jobFilter = jobFilter.filter({$0.requiredSkills?.contains(skill) ?? false})
        } else if let resource = resource {
            jobFilter = jobFilter.filter({$0.requiredResources?.contains(resource) ?? false})
        }

        if !jobFilter.isEmpty {
            self.job = jobFilter.randomElement()
            self.jobStartDate = await game.generateDate(year: game.getYear())
        } else if skill != nil {
            // Perhaps they have all skills but are missing a key resource (only checked when a new skill acquired)
            let skillFilter = await game.availableJobs.filter({$0.requiredSkills?.contains(skill!) ?? false})
            for skilljob in skillFilter {
                for resource in skilljob.requiredResources ?? [] where !self.resources.keys.contains(resource) {
                    self.wantsToBuy(resource: resource, number: 1)
                }
            }
        }

    }
        
    func undoMarriage() {
        self.spouse?.spouse = nil
        self.spouse?.dateOfMarriage = nil
        self.spouse = nil
        self.dateOfMarriage = nil
    }
    
    func asString() -> String {
        var retString = self.name + " (" + String(describing: self.gender).prefix(1).uppercased() + ")"
        //        retString += " ("
        //        for affiliation in affiliations {
        //            retString += " " + affiliation.name
        //        }
        //        retString += ")"
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd/MM/YYYY"
        retString += "\r\nb. " + dateFormat.string(from: self.dateOfBirth)
        //        if self.job == nil {
        //            retString += " is unemployed"
        //        } else {
        //            retString += " is a \(self.job!.name)"
        //        }
        if self.dateOfDeath == nil {
            //            retString += " and is currently \(self.age()) years old"
        } else {
            retString += "\r\nd. " + dateFormat.string(from: self.dateOfDeath!)
            //            retString += " dying at the age of \(self.age()) years old"
            //            retString += " due to \(self.causeOfDeath!)"
        }
        
        if let spouse = self.spouse {
            retString += "\r\nm. \(spouse.name)"
        }
        if self.descendants.filter({$0.dateOfDeath == nil}).count > 0 {
            retString += "\r\n\(self.descendants.filter({$0.dateOfDeath == nil}).count) children"
        }
        
        return retString
    }
    
    func asDebugString() -> String {
        var retString = self.name

        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "YYYY"
        retString += " " + dateFormat.string(from: self.dateOfBirth) + "-"

        if self.dateOfDeath == nil {
//            retString += " and is currently \(self.age()) years old"
        } else {
            retString += dateFormat.string(from: self.dateOfDeath!)
            retString += " due to \(self.causeOfDeath ?? "Unknown")"
        }
        
        if let spouse = self.spouse {
            retString += " m. \(spouse.name)"
        }
        if self.descendants.count > 0 {
            retString += " \(self.descendants.count) children"
        }

        if let job = self.job {
            retString += " is a \(job.name)"
        }
        
        for (resource, count) in self.resources ?? [:] {
            retString += " has \(count) \(resource.name)"
        }

        return retString
    }

    func asFamilyTreeString() -> String {
        var retString = self.name

        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "YYYY"
        retString += "\r\n" + dateFormat.string(from: self.dateOfBirth) + "-"

        if self.dateOfDeath == nil {
//            retString += " and is currently \(self.age()) years old"
        } else {
            retString += dateFormat.string(from: self.dateOfDeath!)
        }
        
//        if self.spouse != nil {
//            retString += "\r\nm. \(self.spouse!.name)"
//        }
//        if self.descendants.count > 0 {
//            retString += "\r\n\(self.descendants.count) children"
//        }
        
        return retString
    }
    
    func moves(to: Town, family: Bool = false) {
        if family {
            if let spouse = self.spouse, spouse.location == self.location {
                spouse.location = to
            }
            
            for child in self.descendants where child.location == self.location {
                child.location = to
            }
        }

        self.location = to
    }
    
    func treeDepth() -> Int {
        if self.descendants.count == 0 { return 1 }
        
        var maxDepth = 0
        for child in self.descendants {
            let childDepth = child.treeDepth()
            if childDepth > maxDepth {
                maxDepth = childDepth
            }
        }
        
        return maxDepth + 1
    }
    
    func treeWidth() -> Int {
        if self.descendants.count == 0 { return 0 }
        
        var maxWidth = self.descendants.count
        for child in self.descendants {
            let childWidth = child.treeWidth()
            if childWidth > maxWidth {
                maxWidth = childWidth
            }
        }
        
        return maxWidth
    }

    func buildTreeNode() -> [TreeNode] {
        var fullNode: [TreeNode] = []
        for child in self.descendants {
            fullNode.append(TreeNode(value: child.asFamilyTreeString(), description: child.asString(),
                                     underlying: child,
                                     active: child.dateOfDeath == nil ? true : false, children: child.buildTreeNode()))
        }

        return fullNode
    }
}

extension Person: Hashable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

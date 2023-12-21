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
        case affiliation
        case jobDistribution
        case genderDistribution
    }

    let count: Int
    let minAge: Int
    let maxAge: Int
    let affiliation: Affiliation?
    let jobDistribution: [String: Float]
    var genderDistribution: [Sex: Float]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decode(Int.self, forKey: .count)
        self.minAge = try container.decode(Int.self, forKey: .minAge)
        self.maxAge = try container.decode(Int.self, forKey: .maxAge)
        self.jobDistribution = try container.decode([String: Float].self, forKey: .jobDistribution)
        self.genderDistribution = try container.decodeIfPresent([Sex: Float].self, forKey: .genderDistribution)

        // Look up the affilliations through its name from the ConfigLoader
        var strAffil = try container.decodeIfPresent(String.self, forKey: .affiliation)
        self.affiliation = ConfigLoader.affiliations.first(where: {$0.name == strAffil})!
    }

    init (count: Int, minAge: Int, maxAge: Int, affiliation: Affiliation? = nil, jobDistribution: [String: Float]? = [:], genderDistribution: [Sex: Float]? = [:]) {
        self.count = count
        self.minAge = minAge
        self.maxAge = maxAge
        self.genderDistribution = genderDistribution
        self.jobDistribution = jobDistribution ?? [:]
        self.affiliation = affiliation
    }
}

struct Name: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case gender
        case affiliation
    }

    let name: String
    let gender: Sex
    let affiliation: Set<Affiliation>?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.gender = try container.decode(Sex.self, forKey: .gender)

        // Look up the affilliations through its name from the ConfigLoader
        var strAffil = try container.decodeIfPresent([String].self, forKey: .affiliation)
        var nameAfils: Set<Affiliation> = []
        for afil in strAffil ?? [] {
            nameAfils.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.affiliation = nameAfils
    }

}
extension Name: Hashable {
    static func == (lhs: Name, rhs: Name) -> Bool {
        return lhs.name == rhs.name && lhs.gender == rhs.gender && lhs.affiliation == rhs.affiliation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(gender)
        hasher.combine(affiliation)
    }
}


class Person: Codable { //swiftlint:disable:this type_body_length
    // TODO: Refactor to move strings for events and/or string displays elsewhere
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
    var affiliations: Set<Affiliation> = []
    var location: Town?
    var injuries: Set<Injury> = []
    var treatedInjuries: Set<Injury> = []
    var job: Job?
    var jobStartDate: Date?
    var skills: Set<Skill>? = []
    var spouse: Person?
    var descendants: Set<Person> = []
    var tryingForFamily: Bool = true
    var resources: [Resource: Int] = [:]
    var wantedResources: [Resource: Int] = [:]
    var familyBusiness: JobType = .general
    var health: Float = 1

    init(name: String, dateOfBirth: Date, gender: Sex, game: GameEngine) async {
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
            .filter({$0.wealth < self.wealth()})
            .filter({$0.affiliations?.isSubset(of: self.affiliations) ?? true})
            .sorted(by: {$0.wealth > $1.wealth}).first
    }

    func wealth(recursed: Bool = false) -> Float {
        var wealth: Float = 0
        for (resource, count) in resources {
            if resource.name == "Coin" {
                wealth += Float(count)
            } else {
                for exchRate in ConfigLoader.rates.filter({$0 is ExchangeRate}) {
                    let conversion = exchRate as? ExchangeRate
                    if conversion != nil && conversion?.sellResource.name ==  "Coin" && conversion?.buyResource == resource {
                        wealth += (conversion!.rate * Float(count))
                    } 
                }
            }
        }

        // Wealth is shared so if there is a spouse add their wealth
        if spouse != nil && !recursed {
            wealth += spouse!.wealth(recursed: true)
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
        
        if injury.cure != nil {
            desc += "Can be cured at " + (injury.cure!.location?.name ?? "UNSPECIFIED")
            desc += ".  Which will reduce the change of death to " + String((injury.treatedMortality?.getRate(person: self) ?? 0) * 100)
            desc += "%\r\n"
        }

        await addEvent(title: "New Illness/Injury", description: desc, game: game)
    }
    
    func addMarriageEvent(other: Person, game: GameEngine) async {

        var desc = other.name + " would like to marry\r\n"
        desc += "They are " + String(other.age) + " years old"
        if other.job != nil {
            desc += " and a " + other.job!.name
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
        if self.resources[resource] == nil {
            self.resources[resource] = 1
        } else {
            self.resources[resource]! += 1
        }

        if self.wantedResources[resource] != nil {
            self.wantedResources[resource]! -= 1
        }

    }

    func removeResource(resource: Resource) {
        for res in self.resources.keys.filter({$0.name == resource.name}).sorted(by: {$0.age > $1.age})
        where (self.resources[res] ?? 0) > 0 {
            self.resources[res]! -= 1

            if self.resources[res]! == 0 {
                self.resources.removeValue(forKey: res)
            }
            return
        }
    }

    func wantsToBuy(resource: Resource, number: Int) {
        let wantedRes = resource.newInstance()
        if self.wantedResources[wantedRes] == nil {
            self.wantedResources[wantedRes] = number
        } else {
            self.wantedResources[wantedRes]! += number
        }
    }
    

    func marries(game: GameEngine, minAge: Int = 0, locationFilter: LocationType? = .town) async {
        // Select a random spouse for this person who is not already married
        if self.dateOfMarriage != nil && self.spouse?.dateOfDeath == nil { return } // Only remarry if spouse is dead

        var filter = await game.persons.filter({$0.dateOfMarriage == nil})
        filter = filter.filter({$0.dateOfDeath == nil})
        filter = filter.filter({$0.age > minAge})

        if self.gender == Sex.female {
            filter = filter.filter({$0.gender == .male})
        } else {
            filter = filter.filter({$0.gender == .female})
        }
        
        // Check for any incompatible affiliations
        for affiliation in affiliations where affiliation.dislikedAffiliations != nil {
                filter = filter.filter({affiliation.dislikedAffiliations!.isDisjoint(with: $0.affiliations)})
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
            let spouse = filter.randomElement()!
            self.marries(spouse: spouse, game: game)
            if await game.getActivePerson() == self {
                await self.addMarriageEvent(other: self.spouse!, game: game)
            }
        }
    }
    
    func dies(game: GameEngine, fairInheritance: Bool = false) async {
        // Set date of death
        self.dateOfDeath = await game.generateDate(year: game.year)
                
        // Perform any inheritance of resources
        for resource in self.resources.keys where resource.inheritable {
            if fairInheritance && self.spouse != nil && self.spouse?.dateOfDeath == nil {
                while self.resources[resource] ?? 0 > 0 {
                    self.spouse?.addResource(resource: resource)
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
            } else if !affils.isDisjoint(with: $0.affiliation!) {
                return true
            } else {
                return $0.affiliation!.contains(affiliation)
            }
        })
        if gender == .male {
            filter = filter.filter({$0.gender == .male})
        } else {
            filter = filter.filter({$0.gender == .female})
        }
        let rand = ConfigLoader.names.randomElement()!
        name = filter.randomElement() ?? rand
        
        // Use game date -1 to indicate child born in the last year
        let person = await Person(name: name.name, dateOfBirth: game.generateDate(year: game.year - age), gender: name.gender, game: game)
        person.affiliations.insert(affiliation)

        if affiliation.capital != nil {
            person.location = affiliation.capital!
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
                for parentAffil in parentAffils where $0.affiliation!.contains(parentAffil) {
                    return true
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
        if parents.first?.location != nil {
            person.location = parents.first?.location!
        }
        return person
    }
    
    func hasChild(game: GameEngine, patriachy: Bool = true) async {
        if self.gender == Sex.male { return }  // As of today males cannot have children
        
        if self.spouse == nil { return }  // Not married so cannot have children TODO: Switch to relationship rather than marriage?
        
        if self.spouse!.dateOfDeath != nil { return } // Spouse is dead so again cannot have children
        
        if !self.tryingForFamily { return } // No longer trying
        
        let child = await generateRandomPerson(parents: [self, self.spouse!], patriachy: patriachy, game: game)
        
        await self.hasChild(child: child, game: game)
        
        // TODO: Is this needed Add as a NPC
        //await game.addPerson(person: child)
    }
    
    func hasChild(child: Person, game: GameEngine) async {
        // Children inherit characteristics such as location and relation to the player
        child.relatedToThePlayer = self.relatedToThePlayer ? true : (self.spouse?.relatedToThePlayer ?? false)
        child.location = self.location
        if job != nil {
            child.familyBusiness = job!.type ?? .general
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
            if potentialJob?.maxCount ?? 0 > 0 {
                let currCount = await game.persons.filter({!$0.affiliations.isDisjoint(with: self.affiliations)
                    && $0.job == potentialJob
                    && $0.dateOfDeath == nil
                }).count
                if currCount >= potentialJob?.maxCount ?? 0 {
                    // Position is already filled
                    return
                }
            }
            self.job = potentialJob
            self.jobStartDate = startDate
            if self.job?.earnAffiliations != nil {
                self.affiliations.formUnion(self.job!.earnAffiliations!)
            }
            
        }
    }

    func upgradeJob(skill: Skill? = nil, resource: Resource? = nil, game: GameEngine) async {
        let personAge = self.age
        let gameD = await game.getGameDate()
        var jobFilter = await game.availableJobs.filter({$0.meetsRequirements(person: self, gameDate: gameD)})
        jobFilter = jobFilter.filter({$0.allowedGenders.contains(self.gender)})
        if self.affiliations.count > 0 {
            jobFilter = jobFilter.filter({self.affiliations.intersection($0.affiliations ?? []).count > 0})
        } else {
            jobFilter = jobFilter.filter({($0.affiliations ?? []).count == 0})
        }
        if skill != nil {
            jobFilter = jobFilter.filter({$0.requiredSkills?.contains(skill!) ?? false})
        } else if resource != nil {
            jobFilter = jobFilter.filter({$0.requiredResources?.contains(resource!) ?? false})
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
        
        if self.spouse != nil {
            retString += "\r\nm. \(self.spouse!.name)"
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
        
        if self.spouse != nil {
            retString += " m. \(self.spouse!.name)"
        }
        if self.descendants.count > 0 {
            retString += " \(self.descendants.count) children"
        }

        if self.job != nil {
            retString += " is a \(self.job!.name)"
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
            if self.spouse?.location == self.location { self.spouse?.location = to }
            
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
        return lhs.name == rhs.name && lhs.dateOfBirth == rhs.dateOfBirth && lhs.gender == rhs.gender
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(dateOfBirth)
        hasher.combine(gender)
    }
}

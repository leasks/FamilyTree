//
//  Job.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

enum JobType: String, Codable {
    case military
    case trade
    case agriculture
    case general
    case commerce
    case civil
    case academic
    case art
    case hospitality
    case medicine
    case religion
    case construction
}

struct Skill: Codable {
    let id: UUID
    let name: String
    let description: String?
    
    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
    }
}
extension Skill: Hashable {
    static func == (lhs: Skill, rhs: Skill) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Job: Codable { //swiftlint:disable:this type_body_length
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case description
        case minAge
        case maxAge
        case allowedGenders
        case affiliations
        case requiredSkills
        case learnSkills
        case blockedAffiliations
        case earnAffiliations
        case requiredResources
        case produceResource
        case maxCount
        case travels
        case socialClass
    }

    let id: UUID
    var name: String
    var type: JobType?
    var description: String?
    var minAge: Int?
    var maxAge: Int?
    var allowedGenders: Set<Sex> = [Sex.male, Sex.female]
    var affiliationIDs: Set<UUID>? = []
    var requiredSkillIDs: Set<UUID>? = []
    var learnSkillsIDs: [UUID: Int]? = [:]
    var blockedAffiliationIDs: Set<UUID>? = []
    var earnAffiliationIDs: Set<UUID>? = []
    var requiredResourceIDs: Set<UUID>? = []
    var produceResourceIDs: [UUID: Int] = [:]
    var maxCount: Int? = 0
    var travels: Bool = false
    var socialClassID: UUID?
    
    // Computed properties for backward compatibility
    var affiliations: Set<Affiliation>? {
        get {
            guard let ids = affiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            affiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var requiredSkills: Set<Skill>? {
        get {
            guard let ids = requiredSkillIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findSkill(byID: $0) })
        }
        set {
            requiredSkillIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var learnSkills: [Skill: Int]? {
        get {
            guard let ids = learnSkillsIDs else { return nil }
            var result: [Skill: Int] = [:]
            for (id, value) in ids {
                if let skill = ConfigLoader.findSkill(byID: id) {
                    result[skill] = value
                }
            }
            return result
        }
        set {
            learnSkillsIDs = newValue != nil ? Dictionary(uniqueKeysWithValues: newValue!.map { ($0.key.id, $0.value) }) : nil
        }
    }
    
    var blockedAffiliations: Set<Affiliation>? {
        get {
            guard let ids = blockedAffiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            blockedAffiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var earnAffiliations: Set<Affiliation>? {
        get {
            guard let ids = earnAffiliationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            earnAffiliationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var requiredResources: Set<Resource>? {
        get {
            guard let ids = requiredResourceIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findResource(byID: $0) })
        }
        set {
            requiredResourceIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var produceResource: [Resource: Int] {
        get {
            var result: [Resource: Int] = [:]
            for (id, value) in produceResourceIDs {
                if let resource = ConfigLoader.findResource(byID: id) {
                    result[resource] = value
                }
            }
            return result
        }
        set {
            produceResourceIDs = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.id, $0.value) })
        }
    }
    
    var socialClass: SocialClass? {
        get {
            guard let id = socialClassID else { return nil }
            return ConfigLoader.findSocialClass(byID: id)
        }
        set {
            socialClassID = newValue?.id
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decodeIfPresent(JobType.self, forKey: .type)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.minAge = try container.decodeIfPresent(Int.self, forKey: .minAge)
        self.maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)
        self.allowedGenders = try container.decodeIfPresent(Set<Sex>.self, forKey: .allowedGenders) ?? [.male, .female]
        self.travels = try container.decodeIfPresent(Bool.self, forKey: .travels) ?? false
        
        // Decode skills
        let skills = try container.decodeIfPresent(Set<Skill>.self, forKey: .requiredSkills)
        self.requiredSkillIDs = skills != nil ? Set(skills!.map { $0.id }) : []
        
        let learnSkillsDecoded = try container.decodeIfPresent([Skill: Int].self, forKey: .learnSkills)
        self.learnSkillsIDs = learnSkillsDecoded != nil ? Dictionary(uniqueKeysWithValues: learnSkillsDecoded!.map { ($0.key.id, $0.value) }) : [:]

        // Look up resource through the name
        let strResources = try container.decodeIfPresent([String].self, forKey: .requiredResources)
        var resourceIDList: Set<UUID> = []
        for resource in strResources ?? [] {
            if let foundResource = ConfigLoader.resources.first(where: {$0.name == resource}) {
                resourceIDList.insert(foundResource.id)
            } else {
                print("Warning: Resource '\(resource)' not found in ConfigLoader for job '\(self.name)'")
            }
        }
        self.requiredResourceIDs = resourceIDList

        let createResource = try container.decodeIfPresent([String: Int].self, forKey: .produceResource)
        var allData: [UUID: Int] = [:]
        for (resource, count) in createResource ?? [:] {
            if let foundResource = ConfigLoader.resources.first(where: {$0.name == resource}) {
                allData[foundResource.id] = count
            } else {
                print("Warning: Resource '\(resource)' not found in ConfigLoader for job '\(self.name)'")
            }
        }
        self.produceResourceIDs = allData

        // Look up social class through its name if present
        let strClass = try container.decodeIfPresent(String.self, forKey: .socialClass)
        if let strClass = strClass {
            self.socialClassID = ConfigLoader.socialClasses.first(where: {$0.name == strClass})?.id
        }
        
        // Look up the capital through its name from the ConfigLoader
        let strAffils = try container.decodeIfPresent([String].self, forKey: .affiliations)
        var afilIDList: Set<UUID> = []
        for afil in strAffils ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                afilIDList.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for job '\(self.name)'")
            }
        }
        self.affiliationIDs = afilIDList

        let strAffilsBlocked = try container.decodeIfPresent([String].self, forKey: .blockedAffiliations)
        var afilIDListBlocked: Set<UUID> = []
        for afil in strAffilsBlocked ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                afilIDListBlocked.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for job '\(self.name)'")
            }
        }
        self.blockedAffiliationIDs = afilIDListBlocked

        let strAffilsEarn = try container.decodeIfPresent([String].self, forKey: .earnAffiliations)
        var afilIDListEarn: Set<UUID> = []
        for afil in strAffilsEarn ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                afilIDListEarn.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for job '\(self.name)'")
            }
        }
        self.earnAffiliationIDs = afilIDListEarn
        
        self.maxCount = try container.decodeIfPresent(Int.self, forKey: .maxCount)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(minAge, forKey: .minAge)
        try container.encodeIfPresent(maxAge, forKey: .maxAge)
        try container.encode(allowedGenders, forKey: .allowedGenders)
        try container.encode(travels, forKey: .travels)
        
        // Encode skills as full objects
        if let requiredSkillIDs = requiredSkillIDs {
            let skills = Set(requiredSkillIDs.compactMap { ConfigLoader.findSkill(byID: $0) })
            if !skills.isEmpty {
                try container.encode(skills, forKey: .requiredSkills)
            }
        }
        
        if let learnSkillsIDs = learnSkillsIDs {
            var learnSkills: [Skill: Int] = [:]
            for (skillID, value) in learnSkillsIDs {
                if let skill = ConfigLoader.findSkill(byID: skillID) {
                    learnSkills[skill] = value
                }
            }
            if !learnSkills.isEmpty {
                try container.encode(learnSkills, forKey: .learnSkills)
            }
        }
        
        // Encode resource names instead of UUIDs
        if let requiredResourceIDs = requiredResourceIDs {
            let resourceNames = requiredResourceIDs.compactMap { ConfigLoader.findResource(byID: $0)?.name }
            if !resourceNames.isEmpty {
                try container.encode(resourceNames, forKey: .requiredResources)
            }
        }
        
        // Encode produce resources as dictionary of name -> count
        if !produceResourceIDs.isEmpty {
            var produceResourceNames: [String: Int] = [:]
            for (resourceID, count) in produceResourceIDs {
                if let resource = ConfigLoader.findResource(byID: resourceID) {
                    produceResourceNames[resource.name] = count
                }
            }
            if !produceResourceNames.isEmpty {
                try container.encode(produceResourceNames, forKey: .produceResource)
            }
        }
        
        // Encode social class name instead of UUID
        if let socialClassID = socialClassID, let socialClass = ConfigLoader.findSocialClass(byID: socialClassID) {
            try container.encode(socialClass.name, forKey: .socialClass)
        }
        
        // Encode affiliation names instead of UUIDs
        if let affiliationIDs = affiliationIDs {
            let affiliationNames = affiliationIDs.compactMap { ConfigLoader.findAffiliation(byID: $0)?.name }
            if !affiliationNames.isEmpty {
                try container.encode(affiliationNames, forKey: .affiliations)
            }
        }
        
        if let blockedAffiliationIDs = blockedAffiliationIDs {
            let blockedAffiliationNames = blockedAffiliationIDs.compactMap { ConfigLoader.findAffiliation(byID: $0)?.name }
            if !blockedAffiliationNames.isEmpty {
                try container.encode(blockedAffiliationNames, forKey: .blockedAffiliations)
            }
        }
        
        if let earnAffiliationIDs = earnAffiliationIDs {
            let earnAffiliationNames = earnAffiliationIDs.compactMap { ConfigLoader.findAffiliation(byID: $0)?.name }
            if !earnAffiliationNames.isEmpty {
                try container.encode(earnAffiliationNames, forKey: .earnAffiliations)
            }
        }
        
        try container.encodeIfPresent(maxCount, forKey: .maxCount)
    }

    init(id: UUID = UUID(), name: String, description: String? = nil, type: JobType? = nil, minAge: Int? = 0,
         allowedGenders: Set<Sex>? = [Sex.male, Sex.female],
         affiliations: Set<Affiliation>? = [], blockedAffiliations: Set<Affiliation>? = [],
         earnAffiliations: Set<Affiliation>? = [],
         requiredSkills: Set<Skill>? = [], learnSkills: [Skill: Int]? = [:],
         requiredResources: Set<Resource>? = [], produceResource: [Resource: Int]? = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.minAge = minAge
        self.allowedGenders = allowedGenders ?? [Sex.male, Sex.female]
        self.affiliationIDs = affiliations != nil ? Set(affiliations!.map { $0.id }) : []
        self.blockedAffiliationIDs = blockedAffiliations != nil ? Set(blockedAffiliations!.map { $0.id }) : []
        self.earnAffiliationIDs = earnAffiliations != nil ? Set(earnAffiliations!.map { $0.id }) : []
        self.requiredSkillIDs = requiredSkills != nil ? Set(requiredSkills!.map { $0.id }) : []
        self.learnSkillsIDs = learnSkills != nil ? Dictionary(uniqueKeysWithValues: learnSkills!.map { ($0.key.id, $0.value) }) : [:]
        self.requiredResourceIDs = requiredResources != nil ? Set(requiredResources!.map { $0.id }) : []
        self.produceResourceIDs = produceResource != nil ? Dictionary(uniqueKeysWithValues: produceResource!.map { ($0.key.id, $0.value) }) : [:]
    }

    func meetsRequirements(person: Person, gameDate: Date) -> Bool {
        let personAge = person.age
        if minAge ?? 0 <= personAge && maxAge ?? 1000 >= personAge {
            if !allowedGenders.contains(person.gender) { return false } // Job does not support this gender
            
            if person.affiliations.count > 0 {
                if let affiliations = self.affiliations, !affiliations.isEmpty {
                    if affiliations.isDisjoint(with: person.affiliations) {
                        // Person does not have the right affiliation
                        return false
                    }
                }
                
                if let blockedAffiliations = self.blockedAffiliations, !blockedAffiliations.isEmpty {
                    if !blockedAffiliations.isDisjoint(with: person.affiliations) {
                        // Person has a blocked affiliation
                        return false
                    }
                }
            } else if (self.affiliations?.count ?? 0) > 0 {
                // The job has an affiliation requirement but the person has none
                return false
            }
            
            if let personSkills = person.skills, personSkills.count > 0 {
                let requiredSkills = self.requiredSkills ?? personSkills
                if personSkills.intersection(requiredSkills).count != requiredSkills.count {
                    // The person doesn't have the required skills
                    return false
                }
            } else {
                if (self.requiredSkills ?? []).count > 0 {
                    // The job requires skills but the person has none
                    return false
                }
            }
            
            if let requiredResources = self.requiredResources, requiredResources.count > 0 {
                if requiredResources.intersection(person.resources.keys).count != requiredResources.count {
                    // Person doesn't have the necessary resources
                    return false
                }
            }

            if self.socialClass?.wealth ?? -1 > person.wealth() {
                // This job has a social class requirement which is too high for this person
                return false
            }
            return true
        } else {
            // The person doesn't meet the age requirements
            return false
        }
    }
    
//    func checkRequirements(person: Person) -> (Bool, Set<Resource>) {
//        var canCreate = true
//        var needResource: Set<Resource> = []
//        for resource in self.requiredResources ?? [] where person.resources.keys.filter({$0.name == resource.name}).isEmpty {
//            // Can't build so need this resource
//            needResource.insert(resource)
//            canCreate = false
//        }
//
//        return (canCreate, needResource)
//    }

    func doJob(person: Person, game: GameEngine) async {
        if person.job != self { return } // This person doesn't do this job

        // TODO: Perform the activties of the job
        // creating resources and learning skills and relocation
        createResource(person: person)

        await learnSkills(person: person, game: game)

        // Sales jobs also can relocate so carry this out here
        // TODO: should this be every turn or do they return home at random too?
        if travels {
            let alltowns = await game.availableLocations.filter({$0.type == .town}) as? Set<Town>

            if let newlocation = alltowns?.randomElement() {
                person.moves(to: newlocation, family: false)
            }

        }
    }

    func createResource(person: Person) {
        for (resource, vol) in self.produceResource ?? [:] {
            for _ in (1...vol) {
                resource.createResource(person: person)
            }
        }

    }

    func learnSkills(person: Person, game: GameEngine) async {
        guard let jobStartDate = person.jobStartDate else { return }
        let calendar = Calendar(identifier: .gregorian)
        let currDate = await game.getGameDate()
        let jobAge = currDate > jobStartDate ?
        calendar.dateComponents([.year], from: jobStartDate, to: currDate).year ?? 0 :
        0

        for (skill, period) in (learnSkills ?? [:]) where jobAge >= period && !(person.skills?.contains(skill) ?? false) {
            person.skills?.insert(skill)
            await person.addLearnSkillEvent(skill: skill, game: game)
            if await person != game.getActivePerson() {
                await person.upgradeJob(skill: skill, game: game)  // Have a new skill so maybe can get a better job
            }
        }
    }

    func buildTreeNode(game: GameEngine) async -> [TreeNode] {
        var fullNode: [TreeNode] = []
        guard let player = await game.activePerson else { return fullNode }
        let jobs = await game.availableJobs
        if let learnSkills = self.learnSkills, learnSkills.count > 0 {
            for (skill, _) in learnSkills {
                let dependentJobs = await jobs.filter({$0.requiredSkills?.contains(skill) ?? false})
                for child in dependentJobs {
                    await fullNode.append(TreeNode(value: child.name, description: child.details(),
                                                   underlying: child,
                                                   active: child.meetsRequirements(person: player, gameDate: game.getGameDate()),
                                                   children: child.buildTreeNode(game: game)))
                }
            }
        } else if self.requiredSkills?.count ?? 0 == 0 {
            // No skills learnt or required (so probably a root job),  the dependencies will be all jobs requiring no skills
            let dependentJobs = await jobs.filter({($0.requiredSkills?.count ?? 0) == 0})
            for child in dependentJobs {
                await fullNode.append(TreeNode(value: child.name, description: child.details(),
                                               underlying: child,
                                               active: child.meetsRequirements(person: player, gameDate: game.getGameDate()),
                                               children: child.buildTreeNode(game: game)))
            }
        }

        return fullNode

    }

    func details() -> String {
        var retString = self.description ?? ""
        retString += "\r\n"

        // Display gender and age requirements
        if allowedGenders.count < 2 || minAge != nil || maxAge != nil {
            retString += "\r\nRestrictions: "

            if allowedGenders.count < 2 {
                if allowedGenders.contains(.male) {
                    retString += "Men only\r\n"
                } else {
                    retString += "Women only\r\n "
                }
            }
            if let minAge = minAge {
                retString += "Minimum Age " + String(minAge) + "\r\n"
            }

            if let maxAge = maxAge {
                retString += "Maximum Age " + String(maxAge) + "\r\n"
            }

        }

        // Display skill requirements
        if let requiredSkills = requiredSkills {
            retString += "\r\nRequired Skills: "
            for skill in requiredSkills {
                retString += skill.name + "\r\n"
            }
        }
        if let learnSkills = learnSkills {
            retString += "\r\nLearnt Skills: "
            for (skill, years) in learnSkills {
                retString += skill.name + " (" + String(years) + " years)\r\n"
            }
        }

        return retString
    }
}
extension Job: Hashable {
    static func == (lhs: Job, rhs: Job) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

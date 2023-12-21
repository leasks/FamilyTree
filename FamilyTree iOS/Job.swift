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
    let name: String
    let description: String?
}
extension Skill: Hashable {
    static func == (lhs: Skill, rhs: Skill) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct Job: Codable {
    private enum CodingKeys: String, CodingKey {
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

    var name: String
    var type: JobType?
    var description: String?
    var minAge: Int?
    var maxAge: Int?
    var allowedGenders: Set<Sex> = [Sex.male, Sex.female]
    var affiliations: Set<Affiliation>? = []
    var requiredSkills: Set<Skill>? = []
    var learnSkills: [Skill: Int]? = [:]
    var blockedAffiliations: Set<Affiliation>? = []
    var earnAffiliations: Set<Affiliation>? = []
    var requiredResources: Set<Resource>? = []
    var produceResource: [Resource: Int] = [:]
    var maxCount: Int? = 0
    var travels: Bool = false
    var socialClass: SocialClass?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decodeIfPresent(JobType.self, forKey: .type)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.minAge = try container.decodeIfPresent(Int.self, forKey: .minAge)
        self.maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)
        self.allowedGenders = try container.decodeIfPresent(Set<Sex>.self, forKey: .allowedGenders) ?? [.male, .female]
        self.requiredSkills = try container.decodeIfPresent(Set<Skill>.self, forKey: .requiredSkills)
        self.learnSkills = try container.decodeIfPresent([Skill: Int].self, forKey: .learnSkills)
        self.travels = try container.decodeIfPresent(Bool.self, forKey: .travels) ?? false

        // Look up resource through the name
        var strResources = try container.decodeIfPresent([String].self, forKey: .requiredResources)
        var resourceList: Set<Resource> = []
        for resource in strResources ?? [] {
            resourceList.insert(ConfigLoader.resources.first(where: {$0.name == resource})!)
        }
        self.requiredResources = resourceList

        var createResource = try container.decodeIfPresent([String: Int].self, forKey: .produceResource)
        var allData: [Resource: Int] = [:]
        for (resource, count) in createResource ?? [:] {
            allData[ConfigLoader.resources.first(where: {$0.name == resource})!] = count
        }
        self.produceResource = allData

        // Look up social class through its name if present
        var strClass = try container.decodeIfPresent(String.self, forKey: .socialClass)
        if strClass != nil {
            self.socialClass = ConfigLoader.socialClasses.first(where: {$0.name == strClass})
        }
        
        // Look up the capital through its name from the ConfigLoader
        var strAffils = try container.decodeIfPresent([String].self, forKey: .affiliations)
        var afilList: Set<Affiliation> = []
        for afil in strAffils ?? [] {
            afilList.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.affiliations = afilList

        strAffils = try container.decodeIfPresent([String].self, forKey: .blockedAffiliations)
        afilList = []
        for afil in strAffils ?? [] {
            afilList.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.blockedAffiliations = afilList

        strAffils = try container.decodeIfPresent([String].self, forKey: .earnAffiliations)
        afilList = []
        for afil in strAffils ?? [] {
            afilList.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.earnAffiliations = afilList

    }

    init(name: String, description: String? = nil, type: JobType? = nil, minAge: Int? = 0,
         allowedGenders: Set<Sex>? = [Sex.male, Sex.female],
         affiliations: Set<Affiliation>? = [], blockedAffiliations: Set<Affiliation>? = [],
         earnAffiliations: Set<Affiliation>? = [],
         requiredSkills: Set<Skill>? = [], learnSkills: [Skill: Int]? = [:],
         requiredResources: Set<Resource>? = [], produceResource: [Resource: Int]? = [:]) {
        self.name = name
        self.description = description
        self.type = type
        self.minAge = minAge
        self.allowedGenders = allowedGenders ?? [Sex.male, Sex.female]
        self.affiliations = affiliations
        self.blockedAffiliations = blockedAffiliations
        self.earnAffiliations = earnAffiliations
        self.requiredSkills = requiredSkills
        self.learnSkills = learnSkills
        self.requiredResources = requiredResources
        self.produceResource = produceResource ?? [:]
    }

    func meetsRequirements(person: Person, gameDate: Date) -> Bool {
        let personAge = person.age
        if minAge ?? 0 <= personAge && maxAge ?? 1000 >= personAge {
            if !(allowedGenders.contains(person.gender)) { return false } // Job does not support this gender
            
            if person.affiliations.count > 0 {
                if !(self.affiliations ?? []).isEmpty {
                    if self.affiliations!.isDisjoint(with: person.affiliations) {
                        // Person does not have the right affiliation
                        return false
                    }
                }
                
                if !(self.blockedAffiliations ?? []).isEmpty {
                    if !self.blockedAffiliations!.isDisjoint(with: person.affiliations) {
                        // Person has a blocked affiliation
                        return false
                    }
                }
            } else if (self.affiliations?.count ?? 0) > 0 {
                // The job has an affiliation requirement but the person has none
                return false
            }
            
            if person.skills?.count ?? 0 > 0 {
                if person.skills!.intersection(self.requiredSkills ?? person.skills!).count != (self.requiredSkills ?? person.skills!).count  {
                    // The person doesn't have the required skills
                    return false
                }
            } else {
                if (self.requiredSkills ?? []).count > 0 {
                    // The job requires skills but the person has none
                    return false
                }
            }
            
            if (self.requiredResources ?? []).count > 0 {
                if self.requiredResources!.intersection(person.resources.keys).count != self.requiredResources!.count {
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
            var alltowns = await game.availableLocations.filter({$0.type == .town}) as? Set<Town>

            let newlocation = alltowns?.randomElement()
            if newlocation != nil {
                person.moves(to: newlocation!, family: false)
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
        let calendar = Calendar(identifier: .gregorian)
        let currDate = await game.getGameDate()
        let jobAge = currDate > person.jobStartDate! ?
        calendar.dateComponents([.year], from: person.jobStartDate!, to: currDate).year ?? 0 :
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
        let player = await game.activePerson!
        let jobs = await game.availableJobs
        if self.learnSkills?.count ?? 0 > 0 {
            for (skill, _) in self.learnSkills! {
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
            if minAge != nil {
                retString += "Minimum Age " + String(minAge!) + "\r\n"
            }

            if maxAge != nil {
                retString += "Maximum Age " + String(minAge!) + "\r\n"
            }

        }

        // Display skill requirements
        if requiredSkills != nil {
            retString += "\r\nRequired Skills: "
            for skill in requiredSkills! {
                retString += skill.name + "\r\n"
            }
        }
        if learnSkills != nil {
            retString += "\r\nLearnt Skills: "
            for (skill, years) in learnSkills! {
                retString += skill.name + " (" + String(years) + " years)\r\n"
            }
        }

        return retString
    }
}
extension Job: Hashable {
    static func == (lhs: Job, rhs: Job) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

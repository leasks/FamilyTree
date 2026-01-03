//
//  Events.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct AgeRelocationRule: Codable, Hashable {
    let fromLocationID: UUID
    let maxAge: Int
    let toLocationID: UUID
}

struct JobRelocationRule: Codable, Hashable {
    let affiliationID: UUID
    let jobTypeDistribution: [JobType: Float]
    let toLocationID: UUID
    
    static func == (lhs: JobRelocationRule, rhs: JobRelocationRule) -> Bool {
        return lhs.affiliationID == rhs.affiliationID && lhs.toLocationID == rhs.toLocationID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(affiliationID)
        hasher.combine(toLocationID)
    }
}

struct Event: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case triggerYear
        case triggerOrder
        case endYear
        case injuryIDsAdded
        case injuryIDsRemoved
        case affiliationIDsAdded
        case affiliationIDsRemoved
        case convertAffiliationIDs
        case jobIDsAdded
        case jobIDsRemoved
        case locationIDs
        case ageRelocation
        case jobRelocation
        case newNPC
        case removeNPC
        case locationIDsAdded
        case locationIDsRemoved
        case returnOnEnd
    }

    let id: UUID
    var name: String
    var description: String
    var triggerYear: Int
    var triggerOrder: Int?
    var endYear: Int?
    var injuryIDsAdded: Set<UUID>? = []
    var injuryIDsRemoved: Set<UUID>? = []
    var affiliationIDsAdded: Set<UUID>? = []
    var affiliationIDsRemoved: Set<UUID>? = []
    var jobIDsAdded: Set<UUID>? = []
    var jobIDsRemoved: Set<UUID>? = []
    var locationIDs: Set<UUID>?
    var ageRelocationRules: [AgeRelocationRule]?
    var jobRelocationRules: [JobRelocationRule]?
    var newNPC: [NewNPC]?
    var removeNPC: [String: Float]?
    var locationIDsAdded: Set<UUID>? = []
    var locationIDsRemoved: Set<UUID>? = []
    var convertAffiliationIDs: [UUID: UUID] = [:]
    var returnOnEnd: Bool = false
    
    // Computed properties for backward compatibility
    var injuriesAdded: Set<Injury>? {
        get {
            guard let ids = injuryIDsAdded else { return nil }
            return Set(ids.compactMap { ConfigLoader.findInjury(byID: $0) })
        }
        set {
            injuryIDsAdded = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var injuriesRemoved: Set<Injury>? {
        get {
            guard let ids = injuryIDsRemoved else { return nil }
            return Set(ids.compactMap { ConfigLoader.findInjury(byID: $0) })
        }
        set {
            injuryIDsRemoved = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var affiliationsAdded: Set<Affiliation>? {
        get {
            guard let ids = affiliationIDsAdded else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            affiliationIDsAdded = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var affiliationsRemoved: Set<Affiliation>? {
        get {
            guard let ids = affiliationIDsRemoved else { return nil }
            return Set(ids.compactMap { ConfigLoader.findAffiliation(byID: $0) })
        }
        set {
            affiliationIDsRemoved = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var jobsAdded: Set<Job>? {
        get {
            guard let ids = jobIDsAdded else { return nil }
            return Set(ids.compactMap { ConfigLoader.findJob(byID: $0) })
        }
        set {
            jobIDsAdded = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var jobsRemoved: Set<Job>? {
        get {
            guard let ids = jobIDsRemoved else { return nil }
            return Set(ids.compactMap { ConfigLoader.findJob(byID: $0) })
        }
        set {
            jobIDsRemoved = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var location: Set<Location>? {
        get {
            guard let ids = locationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findLocation(byID: $0) })
        }
        set {
            locationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var locationsAdded: Set<Location>? {
        get {
            guard let ids = locationIDsAdded else { return nil }
            return Set(ids.compactMap { ConfigLoader.findLocation(byID: $0) })
        }
        set {
            locationIDsAdded = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var locationsRemoved: Set<Location>? {
        get {
            guard let ids = locationIDsRemoved else { return nil }
            return Set(ids.compactMap { ConfigLoader.findLocation(byID: $0) })
        }
        set {
            locationIDsRemoved = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var convertAffiliation: [Affiliation: Affiliation] {
        get {
            var result: [Affiliation: Affiliation] = [:]
            for (oldID, newID) in convertAffiliationIDs {
                if let oldAffil = ConfigLoader.findAffiliation(byID: oldID),
                   let newAffil = ConfigLoader.findAffiliation(byID: newID) {
                    result[oldAffil] = newAffil
                }
            }
            return result
        }
        set {
            convertAffiliationIDs = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.id, $0.value.id) })
        }
    }
    
    var ageRelocation: [[Location: Int]: Location]? {
        get {
            guard let rules = ageRelocationRules else { return nil }
            var result: [[Location: Int]: Location] = [:]
            for rule in rules {
                if let fromLoc = ConfigLoader.findLocation(byID: rule.fromLocationID),
                   let toLoc = ConfigLoader.findLocation(byID: rule.toLocationID) {
                    result[[fromLoc: rule.maxAge]] = toLoc
                }
            }
            return result
        }
        set {
            if let value = newValue {
                var rules: [AgeRelocationRule] = []
                for (criteria, toLoc) in value {
                    for (fromLoc, maxAge) in criteria {
                        rules.append(AgeRelocationRule(fromLocationID: fromLoc.id, maxAge: maxAge, toLocationID: toLoc.id))
                    }
                }
                ageRelocationRules = rules
            } else {
                ageRelocationRules = nil
            }
        }
    }
    
    var jobRelocation: [[Affiliation: [JobType: Float]]: Location]? {
        get {
            guard let rules = jobRelocationRules else { return nil }
            var result: [[Affiliation: [JobType: Float]]: Location] = [:]
            for rule in rules {
                if let affil = ConfigLoader.findAffiliation(byID: rule.affiliationID),
                   let toLoc = ConfigLoader.findLocation(byID: rule.toLocationID) {
                    result[[affil: rule.jobTypeDistribution]] = toLoc
                }
            }
            return result
        }
        set {
            if let value = newValue {
                var rules: [JobRelocationRule] = []
                for (criteria, toLoc) in value {
                    for (affil, jobDist) in criteria {
                        rules.append(JobRelocationRule(affiliationID: affil.id, jobTypeDistribution: jobDist, toLocationID: toLoc.id))
                    }
                }
                jobRelocationRules = rules
            } else {
                jobRelocationRules = nil
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.triggerYear = try container.decode(Int.self, forKey: .triggerYear)
        self.triggerOrder = try container.decodeIfPresent(Int.self, forKey: .triggerOrder)
        self.endYear = try container.decodeIfPresent(Int.self, forKey: .endYear) ?? self.triggerYear
        self.newNPC = try container.decodeIfPresent([NewNPC].self, forKey: .newNPC)
        self.removeNPC = try container.decodeIfPresent([String: Float].self, forKey: .removeNPC)
        self.returnOnEnd = try container.decodeIfPresent(Bool.self, forKey: .returnOnEnd) ?? false

        // Look up the injuries through its name from the ConfigLoader
        let strInjury = try container.decodeIfPresent([String].self, forKey: .injuryIDsAdded)
        var injIDList: Set<UUID> = []
        for inj in strInjury ?? [] {
            if let foundInjury = ConfigLoader.injuries.first(where: {$0.name == inj}) {
                injIDList.insert(foundInjury.id)
            } else {
                print("Warning: Injury '\(inj)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.injuryIDsAdded = injIDList

        let strInjuryRemoved = try container.decodeIfPresent([String].self, forKey: .injuryIDsRemoved)
        var injIDListRemoved: Set<UUID> = []
        for inj in strInjuryRemoved ?? [] {
            if let foundInjury = ConfigLoader.injuries.first(where: {$0.name == inj}) {
                injIDListRemoved.insert(foundInjury.id)
            } else {
                print("Warning: Injury '\(inj)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.injuryIDsRemoved = injIDListRemoved

        // Look up the affilliations through its name from the ConfigLoader
        let strAffils = try container.decodeIfPresent([String].self, forKey: .affiliationIDsAdded)
        var afilIDList: Set<UUID> = []
        for afil in strAffils ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                afilIDList.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.affiliationIDsAdded = afilIDList

        let strAffilsRemoved = try container.decodeIfPresent([String].self, forKey: .affiliationIDsRemoved)
        var afilIDListRemoved: Set<UUID> = []
        for afil in strAffilsRemoved ?? [] {
            if let foundAffiliation = ConfigLoader.affiliations.first(where: {$0.name == afil}) {
                afilIDListRemoved.insert(foundAffiliation.id)
            } else {
                print("Warning: Affiliation '\(afil)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.affiliationIDsRemoved = afilIDListRemoved

        let conversions = try container.decodeIfPresent([String: String].self, forKey: .convertAffiliationIDs)
        for (old, new) in conversions ?? [:] {
            guard let oldAfil = ConfigLoader.affiliations.first(where: {$0.name == old}),
                  let newAfil = ConfigLoader.affiliations.first(where: {$0.name == new}) else {
                print("Warning: Affiliation conversion '\(old)' -> '\(new)' not found in ConfigLoader for event '\(self.name)'")
                continue
            }
            self.convertAffiliationIDs[oldAfil.id] = newAfil.id
            self.convertAffiliationIDs[oldAfil.id] = newAfil.id
        }
        
        // Look up the jobs through its name from the ConfigLoader
        let strJobs = try container.decodeIfPresent([String].self, forKey: .jobIDsAdded)
        var jobIDList: Set<UUID> = []
        for job in strJobs ?? [] {
            if let foundJob = ConfigLoader.jobs.first(where: {$0.name == job}) {
                jobIDList.insert(foundJob.id)
            } else {
                print("Warning: Job '\(job)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.jobIDsAdded = jobIDList

        let strJobsRemoved = try container.decodeIfPresent([String].self, forKey: .jobIDsRemoved)
        var jobIDListRemoved: Set<UUID> = []
        for job in strJobsRemoved ?? [] {
            if let foundJob = ConfigLoader.jobs.first(where: {$0.name == job}) {
                jobIDListRemoved.insert(foundJob.id)
            } else {
                print("Warning: Job '\(job)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.jobIDsRemoved = jobIDListRemoved

        // Look up the locations through its name from the ConfigLoader
        let strLocations = try container.decodeIfPresent([String].self, forKey: .locationIDsAdded)
        var locIDList: Set<UUID> = []
        for loc in strLocations ?? [] {
            if let foundLocation = ConfigLoader.locations.first(where: {$0.name == loc}) {
                locIDList.insert(foundLocation.id)
            } else {
                print("Warning: Location '\(loc)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.locationIDsAdded = locIDList

        let strLocationsRemoved = try container.decodeIfPresent([String].self, forKey: .locationIDsRemoved)
        var locIDListRemoved: Set<UUID> = []
        for loc in strLocationsRemoved ?? [] {
            if let foundLocation = ConfigLoader.locations.first(where: {$0.name == loc}) {
                locIDListRemoved.insert(foundLocation.id)
            } else {
                print("Warning: Location '\(loc)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.locationIDsRemoved = locIDListRemoved

        let strLocationsEvent = try container.decodeIfPresent([String].self, forKey: .locationIDs)
        var locIDListEvent: Set<UUID> = []
        for loc in strLocationsEvent ?? [] {
            if let foundLocation = ConfigLoader.locations.first(where: {$0.name == loc}) {
                locIDListEvent.insert(foundLocation.id)
            } else {
                print("Warning: Location '\(loc)' not found in ConfigLoader for event '\(self.name)'")
            }
        }
        self.locationIDs = locIDListEvent

        // Finally handle the relocations by looking up locations and affiliations by name
        let ageReloc = try container.decodeIfPresent([[String: Int]: String].self, forKey: .ageRelocation)
        var ageRules: [AgeRelocationRule] = []
        for (ageDetails, reloc) in ageReloc ?? [:] {
            guard let theReloc = ConfigLoader.locations.first(where: {$0.name == reloc}) else {
                print("Warning: Relocation '\(reloc)' not found in ConfigLoader for event '\(self.name)'")
                continue
            }
            for (loc, theAge) in ageDetails {
                guard let theLoc = ConfigLoader.locations.first(where: {$0.name == loc}) else {
                    print("Warning: Location '\(loc)' not found in ConfigLoader for event '\(self.name)'")
                    continue
                }
                ageRules.append(AgeRelocationRule(fromLocationID: theLoc.id, maxAge: theAge, toLocationID: theReloc.id))
            }
        }
        self.ageRelocationRules = ageRules.isEmpty ? nil : ageRules

        let jobReloc = try container.decodeIfPresent([[String: [JobType: Float]]: String].self, forKey: .jobRelocation)
        var jobRules: [JobRelocationRule] = []
        for (relocDetails, reloc) in jobReloc ?? [:] {
            guard let theReloc = ConfigLoader.locations.first(where: {$0.name == reloc}) else {
                print("Warning: Relocation '\(reloc)' not found in ConfigLoader for event '\(self.name)'")
                continue
            }
            for (affil, theJobs) in relocDetails {
                guard let theAffil = ConfigLoader.affiliations.first(where: {$0.name == affil}) else {
                    print("Warning: Affiliation '\(affil)' not found in ConfigLoader for event '\(self.name)'")
                    continue
                }
                jobRules.append(JobRelocationRule(affiliationID: theAffil.id, jobTypeDistribution: theJobs, toLocationID: theReloc.id))
            }
        }
        self.jobRelocationRules = jobRules.isEmpty ? nil : jobRules
    }

    init(id: UUID = UUID(), name: String, description: String, triggerYear: Int, jobsAdded: Set<Job>? = [],
         injuriesAdded: Set<Injury>? = [],
         injuriesRemoved: Set<Injury>? = [], newNPC: [NewNPC]? = []) {
        self.id = id
        self.name = name
        self.description = description
        self.triggerYear = triggerYear
        self.injuryIDsAdded = injuriesAdded != nil ? Set(injuriesAdded!.map { $0.id }) : []
        self.injuryIDsRemoved = injuriesRemoved != nil ? Set(injuriesRemoved!.map { $0.id }) : []
        self.jobIDsAdded = jobsAdded != nil ? Set(jobsAdded!.map { $0.id }) : []
        self.newNPC = newNPC
    }

    func expire(game: GameEngine) async {
        // Remove locations from the injuries added - but don't remove the injury from the game
        // unless no locations left
        var newinjuries: Set<Injury> = []
        for injury in self.injuriesAdded ?? [] {
            if self.location != nil {
                    var newinjury = injury
                if newinjury.location != nil {
                    newinjury.location = newinjury.location?.union(self.location!)
                } else {
                    newinjury.location = self.location!
                }
                    newinjuries.insert(newinjury)
            } else {
                newinjuries.insert(injury)
            }
        }

        await game.removeFromSets(oldInjuries: newinjuries)

        // Return people to original location - have this as a setting on the event
        if returnOnEnd {
            let gameD = await game.getGameDate()
            let minD = await game.getMinDate()
            let maxD = await game.getMaxDate()
            let returnRate = ConfigLoader.rates.first(where: {$0.type == "Return To Pre-Event Location" && $0.startDate ?? minD < gameD && $0.endDate ?? maxD > gameD})
            for (ageDetails, newlocation) in ageRelocation ?? [:] {
                for (oldlocation, age) in ageDetails {
                    for person in await game.persons.filter({$0.dateOfDeath == nil && $0.location == newlocation && $0.age <= age})
                    where await Float.random(in: 0...1) < returnRate?.getRate() ?? 0 {
                        person.location = oldlocation as? Town
                    }
                }
            }

            for (jobDets, newlocation) in jobRelocation ?? [:] {
                for (afil, _) in jobDets {
                    for person in await game.persons.filter({$0.dateOfDeath == nil && $0.location == newlocation && $0.affiliations.contains(afil)}) where Float.random(in: 0...1) < 0.8 {
                        if let spouse = person.spouse {
                            // Send back to their partner
                            person.location = spouse.location
                        } else {
                            // Otherwise send them back to the capital
                            let location = person.affiliations.randomElement()?.capital
                            person.location = location
                        }
                    }
                }
            }
        }

        // Apply any affiliation conversions and removal of players - this is when the event ends
        await applyConversions(game: game)

        if self.removeNPC != nil {
            await applyNPCRemoval(game: game)
        }
    }

    func apply(game: GameEngine) async {
        // First up, if the event has a location then any new injuries must inherit it
        var newinjuries: Set<Injury> = []
        for injury in self.injuriesAdded ?? [] {
            if let eventLocation = self.location {
                var newinjury = injury
                if let injuryLocation = newinjury.location {
                    newinjury.location = injuryLocation.union(eventLocation)
                } else {
                    newinjury.location = eventLocation
                }
                newinjuries.insert(newinjury)
            } else {
                newinjuries.insert(injury)
            }
        }

        // Add new injuries & affiliations
        await game.addToSets(newInjuries: newinjuries, newAffiliations: affiliationsAdded ?? [], newJobs: jobsAdded ?? [])

        // Take injuries away & affiliations
        await game.removeFromSets(oldInjuries: self.injuriesRemoved ?? [], oldAffiliations: affiliationsRemoved ?? [], oldJobs: jobsRemoved ?? [])

        // Add extra NPCs if any
        if self.newNPC != nil {
            await applyNPC(game: game)
        }

        await relocations(game: game)

        await applyLocations(game: game)
    }

    func applyLocations(game: GameEngine) async {
        if let locationsAdded = locationsAdded, locationsAdded.count > 0 {
            await game.addToSets(newLocations: locationsAdded)

            // Relocate some of the founding affiliation in to the new town
            // TODO: Limit this to those people who are in the county only
            for location in locationsAdded {
                if let town = location as? Town, let foundedBy = town.foundedBy {
                    let founders = await game.persons.filter({$0.affiliations.contains(foundedBy)})
                    let count = founders.count
                    if count > 2 {
                        let relocate = Int.random(in: 1...(count/2))
                        
                        for _ in 1...relocate {
                            founders.randomElement()?.location = town
                        }
                    }
                }
            }
        }

        if let locationsRemoved = locationsRemoved, locationsRemoved.count > 0 {
            await game.removeFromSets(oldLocations: locationsRemoved)

            // Relocate the old inhabitants
            for location in locationsRemoved {
                if let town = location as? Town {
                    for person in await game.persons.filter({$0.location?.name == town.name}) {
                        person.location = await game.availableLocations.randomElement() as? Town
                    }
                }
            }
        }
    }

    func applyNPC(game: GameEngine) async {
        guard let newNPC = newNPC else { return }
        for npc in newNPC {
            for _ in 1...Int.random(in: Int(Double(npc.count) * 0.8)...Int(Double(npc.count) * 1.2)) {
                let minAge = npc.minAge
                let maxAge = npc.maxAge
                let personAge = Int.random(in: minAge...maxAge)
                let affil = npc.affiliation ?? Affiliation(name: "None")
                var person: Person = await Person(name: "NOTHING", dateOfBirth: game.generateDate(year: game.year), gender: .male, game: game)

                if Float.random(in: 0...1) < npc.genderDistribution?[Sex.male] ?? 0.5 {
                    person = await person.generateRandomPerson(affiliation: affil, gender: Sex.male, age: personAge, game: game)
                } else {
                    person = await person.generateRandomPerson(affiliation: affil, gender: Sex.female, age: personAge, game: game)
                }
                person.affiliations = [affil]

                if (self.location?.count ?? 0) > 0 {
                    person.location = self.location?.randomElement()  as? Town
                } else if person.location == nil {
                    person.location = await game.availableLocations.filter({$0.type == .town}).randomElement() as? Town
                }

                let randJob = Float.random(in: 0...1)
                var counter: Float = 0
                for npcJob in npc.jobDistribution.sorted(by: {$0.value > $1.value}) {
                    let thisJob = await game.availableJobs.first(where: {$0.name == npcJob.key})
                    if randJob < counter + npcJob.value &&
                        (thisJob?.minAge ?? 0) <= personAge &&
                        (thisJob?.maxAge ?? 1000) >= personAge &&
                        thisJob?.allowedGenders.contains(person.gender) ?? true {
                        person.job = thisJob
                        person.jobStartDate = await game.generateDate(year: game.year -
                                                                      Int.random(in: 0...(personAge - (thisJob?.minAge ?? 0))))
                        break
                    } else {
                        counter += npcJob.value
                    }
                }

                // Preload skills and resources to meet the job reqs
                if let job = person.job {
                    person.skills = job.requiredSkills

                    for resource in job.requiredResources ?? [] {
                        person.addResource(resource: resource)
                    }

                    if let socialClass = job.socialClass, socialClass.wealth > 0 {
                        let coin = Resource(name: "Coin")
                        while person.wealth() <= socialClass.wealth {
                            person.addResource(resource: coin)
                        }
                    }

                    // Do job once to generate resources for trading
                    await job.doJob(person: person, game: game)
                }

            }
        }
    }

    func applyNPCRemoval(game: GameEngine) async {
        guard let removeNPC = removeNPC else { return }
        // And remove NPCs that are no longer required
        for (jobname, rate) in removeNPC {
            let job = Job(name: jobname)
            for person in await game.persons.filter({$0.job == job}) where Float.random(in: 0...1) <= rate {
                await game.removePerson(person: person)
            }
        }
    }

    func relocations(game: GameEngine) async {
        
        // Relocate people by age if specificed
        for (criteria, newlocation) in self.ageRelocation ?? [:] {
            for (currlocation, agelimit) in criteria {
                let relocating = await game.persons.filter({$0.location == currlocation})
                for person in relocating where person.age <= agelimit {
                    person.location = newlocation as? Town
                }
            }
        }

        // Relocate people by job type if specified
        for (criteria, newlocation) in self.jobRelocation ?? [:] {
            for (currAffil, jobcriteria) in criteria {
                for (jobtype, pct) in jobcriteria {
                    let relocating = await game.persons.filter({$0.affiliations.contains(currAffil) && $0.job?.type == jobtype})
                    for person in relocating where Float.random(in: 0...1) < pct {
                        person.location = newlocation as? Town
                    }
                }
            }
        }

    }

    func applyConversions(game: GameEngine) async {
        for (curAfil, newAfil) in self.convertAffiliation {
            for person in await game.persons.filter({$0.affiliations.contains(curAfil) && $0.dateOfDeath == nil}) {
                person.affiliations.insert(newAfil)
            }
        }
    }
}
extension Event: Hashable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

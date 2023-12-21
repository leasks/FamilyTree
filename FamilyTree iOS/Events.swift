//
//  Events.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Event: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case triggerYear
        case triggerOrder
        case endYear
        case injuriesAdded
        case injuriesRemoved
        case affiliationsAdded
        case affiliationsRemoved
        case convertAffiliation
        case jobsAdded
        case jobsRemoved
        case location
        case ageRelocation
        case jobRelocation
        case newNPC
        case removeNPC
        case locationsAdded
        case locationsRemoved
        case returnOnEnd
    }

    var name: String
    var description: String
    var triggerYear: Int
    var triggerOrder: Int?
    var endYear: Int?
    var injuriesAdded: Set<Injury>? = []
    var injuriesRemoved: Set<Injury>? = []
    var affiliationsAdded: Set<Affiliation>? = []
    var affiliationsRemoved: Set<Affiliation>? = []
    var jobsAdded: Set<Job>? = []
    var jobsRemoved: Set<Job>? = []
    var location: Set<Location>?
    var ageRelocation: [[Location: Int]: Location]?
    var jobRelocation: [[Affiliation: [JobType: Float]]: Location]?
    var newNPC: [NewNPC]?
    var removeNPC: [String: Float]?
    var locationsAdded: Set<Location>? = []
    var locationsRemoved: Set<Location>? = []
    var convertAffiliation: [Affiliation: Affiliation] = [:]
    var returnOnEnd: Bool = false

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.triggerYear = try container.decode(Int.self, forKey: .triggerYear)
        self.triggerOrder = try container.decodeIfPresent(Int.self, forKey: .triggerOrder)
        self.endYear = try container.decodeIfPresent(Int.self, forKey: .endYear) ?? self.triggerYear
        self.newNPC = try container.decodeIfPresent([NewNPC].self, forKey: .newNPC)
        self.removeNPC = try container.decodeIfPresent([String: Float].self, forKey: .removeNPC)
        self.returnOnEnd = try container.decodeIfPresent(Bool.self, forKey: .returnOnEnd) ?? false

        // Look up the injuries through its name from the ConfigLoader
        var strInjury = try container.decodeIfPresent([String].self, forKey: .injuriesAdded)
        var injList: Set<Injury> = []
        for inj in strInjury ?? [] {
            injList.insert(ConfigLoader.injuries.first(where: {$0.name == inj})!)
        }
        self.injuriesAdded = injList

        strInjury = try container.decodeIfPresent([String].self, forKey: .injuriesRemoved)
        injList = []
        for inj in strInjury ?? [] {
            injList.insert(ConfigLoader.injuries.first(where: {$0.name == inj})!)
        }
        self.injuriesRemoved = injList

        // Look up the affilliations through its name from the ConfigLoader
        var strAffils = try container.decodeIfPresent([String].self, forKey: .affiliationsAdded)
        var afilList: Set<Affiliation> = []
        for afil in strAffils ?? [] {
            afilList.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.affiliationsAdded = afilList

        strAffils = try container.decodeIfPresent([String].self, forKey: .affiliationsRemoved)
        afilList = []
        for afil in strAffils ?? [] {
            afilList.insert(ConfigLoader.affiliations.first(where: {$0.name == afil})!)
        }
        self.affiliationsRemoved = afilList

        let conversions = try container.decodeIfPresent([String: String].self, forKey: .convertAffiliation)
        for (old, new) in conversions ?? [:] {
            let oldAfil = ConfigLoader.affiliations.first(where: {$0.name == old})!
            let newAfil = ConfigLoader.affiliations.first(where: {$0.name == new})!
            self.convertAffiliation[oldAfil] = newAfil
        }
        
        // Look up the jobs through its name from the ConfigLoader
        var strJobs = try container.decodeIfPresent([String].self, forKey: .jobsAdded)
        var jobList: Set<Job> = []
        for job in strJobs ?? [] {
            jobList.insert(ConfigLoader.jobs.first(where: {$0.name == job})!)
        }
        self.jobsAdded = jobList

        strJobs = try container.decodeIfPresent([String].self, forKey: .jobsRemoved)
        jobList = []
        for job in strJobs ?? [] {
            jobList.insert(ConfigLoader.jobs.first(where: {$0.name == job})!)
        }
        self.jobsRemoved = jobList

        // Look up the locations through its name from the ConfigLoader
        var strLocations = try container.decodeIfPresent([String].self, forKey: .locationsAdded)
        var locList: Set<Location> = []
        for loc in strLocations ?? [] {
            locList.insert(ConfigLoader.locations.first(where: {$0.name == loc})!)
        }
        self.locationsAdded = locList

        strLocations = try container.decodeIfPresent([String].self, forKey: .locationsRemoved)
        locList = []
        for loc in strLocations ?? [] {
            locList.insert(ConfigLoader.locations.first(where: {$0.name == loc})!)
        }
        self.locationsRemoved = locList

        strLocations = try container.decodeIfPresent([String].self, forKey: .location)
        locList = []
        for loc in strLocations ?? [] {
            locList.insert(ConfigLoader.locations.first(where: {$0.name == loc})!)
        }
        self.location = locList

        // Finally handle the relocations by looking up locations and affiliations by name
        let ageReloc = try container.decodeIfPresent([[String: Int]: String].self, forKey: .ageRelocation)
        var allAgeData: [[Location: Int]: Location] = [:]
        for (ageDetails, reloc) in ageReloc ?? [:] {
            let theReloc = ConfigLoader.locations.first(where: {$0.name == reloc})
            var theAgeData: [Location: Int] = [:]
            for (loc, theAge) in ageDetails {
                let theLoc = ConfigLoader.locations.first(where: {$0.name == loc})!

                theAgeData[theLoc] = theAge
                allAgeData[theAgeData] = theReloc
            }
        }
        self.ageRelocation = allAgeData

        var jobReloc = try container.decodeIfPresent([[String: [JobType: Float]]: String].self, forKey: .jobRelocation)
        var allJobData: [[Affiliation: [JobType: Float]]: Location] = [:]
        for (relocDetails, reloc) in jobReloc ?? [:] {
            let theReloc = ConfigLoader.locations.first(where: {$0.name == reloc})
            var theJobData: [Affiliation: [JobType: Float]] = [:]
            for (affil, theJobs) in relocDetails {
                let theAffil = ConfigLoader.affiliations.first(where: {$0.name == affil})!

                theJobData[theAffil] = theJobs
                allJobData[theJobData] = theReloc
            }
        }
        self.jobRelocation = allJobData
    }

    init(name: String, description: String, triggerYear: Int, jobsAdded: Set<Job>? = [],
         injuriesAdded: Set<Injury>? = [],
         injuriesRemoved: Set<Injury>? = [], newNPC: [NewNPC]? = []) {
        self.name = name
        self.description = description
        self.triggerYear = triggerYear
        self.injuriesAdded = injuriesAdded
        self.injuriesRemoved = injuriesRemoved
        self.jobsAdded = jobsAdded
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
                        if person.spouse != nil {
                            // Send back to their partner
                            person.location = person.spouse!.location
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
        if locationsAdded?.count ?? 0 > 0 {
            await game.addToSets(newLocations: locationsAdded!)

            // Relocate some of the founding affiliation in to the new town
            // TODO: Limit this to those people who are in the county only
            for location in locationsAdded! {
                let town = location as? Town
                if town != nil && town?.foundedBy != nil {
                    let founders = await game.persons.filter({$0.affiliations.contains(town!.foundedBy!)})
                    let count = founders.count
                    if count > 2 {
                        let relocate = Int.random(in: 1...(count/2))
                        
                        for _ in 1...relocate {
                            founders.randomElement()?.location = town!
                        }
                    }
                }
            }
        }

        if locationsRemoved?.count ?? 0 > 0 {
            await game.removeFromSets(oldLocations: locationsRemoved!)

            // Relocate the old inhabitants
            for location in locationsRemoved! {
                let town = location as? Town
                if town != nil {
                    for person in await game.persons.filter({$0.location?.name == town!.name}) {
                        person.location = await game.availableLocations.randomElement() as? Town
                    }
                }
            }
        }
    }

    func applyNPC(game: GameEngine) async {
        for npc in newNPC! {
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
                if person.job != nil {
                    person.skills = person.job?.requiredSkills

                    for resource in person.job?.requiredResources ?? [] {
                        person.addResource(resource: resource)
                    }

                    if person.job?.socialClass?.wealth ?? 0 > 0 {
                        let coin = Resource(name: "Coin")
                        while person.wealth() <= person.job!.socialClass!.wealth {
                            person.addResource(resource: coin)
                        }
                    }

                    // Do job once to generate resources for trading
                    await person.job?.doJob(person: person, game: game)
                }

            }
        }
    }

    func applyNPCRemoval(game: GameEngine) async {
        // And remove NPCs that are no longer required
        for (jobname, rate) in self.removeNPC! {
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
        return lhs.name == rhs.name && lhs.triggerYear == rhs.triggerYear && lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(triggerYear)
        hasher.combine(description)
    }
}

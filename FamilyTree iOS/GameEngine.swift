//
//  GameEngine.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation
import UIKit

actor GameEngine {
    let calendar = Calendar(identifier: .gregorian)
    var year: Int
    var month: Int
    var generation: Int = 0
    var availableInjuries: Set<Injury> = []
    var availableAffiliations: Set<Affiliation> = []
    var availableJobs: Set<Job> = []
    var availableLocations: Set<Location> = []
    var availableClasses: Set<SocialClass> = []
    var running: Bool = true
    var root: Person?
    var activePerson: Person?
    var activeEvent: [Event] = []
    var persons: Set<Person> = []

//    static var theGame: GameEngine?

    init() {
        self.year = 0
        self.month = 12
    }
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    func setActivePerson(person: Person) {
        generation += 1
        activePerson = person
    }
    
    func getActivePerson() -> Person? {
        return activePerson
    }

    func getYear() -> Int {
        return year
    }

    func active() -> Bool {
        return running
    }
    
    func endGame() {
        self.running = false
    }

    func removeEvent() -> Event? {
        if self.activeEvent.count > 0 {
            return self.activeEvent.removeFirst()
        } else {
            return nil
        }
    }

    func addPerson(person: Person) {
        self.persons.insert(person)
    }

    func removePerson(person: Person) {
        self.persons.remove(person)
    }

    func addToSets(newInjuries: Set<Injury> = [], newAffiliations: Set<Affiliation> = [], newJobs: Set<Job> = [], newLocations: Set<Location> = []) {
        for injury in newInjuries {
            self.availableInjuries.mergeInsert(injury)
        }
        self.availableJobs.formUnion(newJobs)
        for afil in newAffiliations {
            self.availableAffiliations.mergeInsert(afil)
        }
        self.availableLocations.formUnion(newLocations)
    }

    func removeFromSets(oldInjuries: Set<Injury> = [], oldAffiliations: Set<Affiliation> = [], oldJobs: Set<Job> = [], oldLocations: Set<Location> = []) {
        for injury in oldInjuries {
            self.availableInjuries.removeAttributes(injury)
        }
        self.availableAffiliations.subtract(oldAffiliations)
        self.availableJobs.subtract(oldJobs)
        self.availableLocations.subtract(oldLocations)
    }

    func setYear(_ year: Int) async {
        self.year = year
    }

    func addActiveEvent(_ event: Event) {
        self.activeEvent.append(event)
    }

    func initPlayer(name: String, gender: Sex, affiliation: Affiliation) async {
        let components = DateComponents(year: self.year - Int.random(in: 10...14), month: Int.random(in: 1...12), day: Int.random(in: 0...28))
        let birthD = calendar.date(from: components)!
        
        let person = await Person(name: name, dateOfBirth: birthD, gender: gender, game: self)
        person.affiliations.insert(affiliation)

        if affiliation.capital != nil {
            person.location = affiliation.capital!
        }

        person.isThePlayer = true
        person.relatedToThePlayer = true
        self.activePerson = person
        self.root = person
        self.running = true
    }

    func initGame() async {
        // Run any initialisation event
//        ConfigLoader.load()

        let gameYr = getYear()
        await generateLocationEvents()
        for event in ConfigLoader.events.filter({$0.triggerYear == gameYr}) {
            await event.apply(game: self)
        }

//        let person = await game.getActivePerson()!

        // Do an end turn for any NPCs to marry and create children and generate resources
        await npcEndTurnUpdates()
    }

    func playerEndTurnUpdates() async {

        // First apply to the active player
        let player = self.getActivePerson()
        if player != nil {
            player!.age += 1
            for rate in ConfigLoader.rates {
                await rate.apply(person: player!, game: self)
            }

            for injury in availableInjuries {
                await injury.apply(person: player!, game: self, isPlayer: true)
            }

            await player!.job?.doJob(person: player!, game: self)

            for (resource, count) in player!.resources where resource.lifespan > 0 {
                player!.resources[resource] = nil
                resource.age += 1

                if resource.age <= resource.lifespan {
                    player!.resources[resource] = count
                }
            }
        }

    }

    func endTurn() async {
        await self.removeDeadCharacters()

        // End the game turn and advance the clock
        self.year += 1

        // Generate any inter-tribe battles
        let battleRate = ConfigLoader.rates.first(where: {$0.type == "Inter-Tribe Battle" && $0.startDate ?? getMinDate() < getGameDate() && $0.endDate ?? getMaxDate() > getGameDate()})
        for affiliation in availableAffiliations where Float.random(in: 0...1) < battleRate?.getRate() ?? 0 {
            generateBattleEvent(attacker: affiliation)
        }

        // Expire old events
        for event in ConfigLoader.events.filter({$0.endYear == (self.year - 1)}) {
            await event.expire(game: self)
        }

        for location in availableLocations {
            var town = location as? Town
            let event = town?.createRulerEvents(year: self.year - 1)
            if event != nil {
                await event?.expire(game: self)

                // Remove dislikes as the takeover happened
                town?.rulers[self.year - 1]?.dislikedAffiliations?.remove(town?.ruler ?? Affiliation(name: "Dummy"))
                town?.ruler?.dislikedAffiliations?.remove(town?.rulers[self.year - 1] ?? Affiliation(name: "Dummy"))
            }
        }

        // Add any newly triggered events
        self.activeEvent = []
        for event in ConfigLoader.events.filter({$0.triggerYear == self.year}).sorted(by: {$0.triggerOrder ?? 0 < $1.triggerOrder ?? 0}) {
            print(event.description)
            await event.apply(game: self)
            self.activeEvent.append(event)
        }

        // Add any location ruler changes
        for location in availableLocations {
            let town = location as? Town
            let event = town?.createRulerEvents(year: self.year)
            if event != nil {
                print(event?.description)
                await event?.apply(game: self)
                town?.ruler = town?.rulers[self.year]
                // TODO: Only add these events when they are impacting players location (town, county or region?)
                self.activeEvent.append(event!)
            }
        }

        await playerEndTurnUpdates()
        await npcEndTurnUpdates()

    }

    func npcEndTurnUpdates() async {
        // Apply any NPC rules based on rates, but only to alive NPCs
        //        await withTaskGroup(of: Void.self) { taskGroup in
        for character in persons.filter({$0.dateOfDeath == nil}) {
            // First of all if this is the active player then return
            if character == activePerson { continue }

            // Age the character
            character.age += 1

            for rate in ConfigLoader.rates {
                //taskGroup.addTask { await rate.apply(person: character, game: self) }
                await rate.apply(person: character, game: self)
            }

            for injury in availableInjuries {
                await injury.apply(person: character, game: self)
            }

            // If the character died after applying injuries don't bother with the rest
            if character.dateOfDeath != nil { continue }

            // Do trading
            self.tradeMatching(buyer: character)
            self.makeTrades(buyer: character)

            if character.job != nil {
                await character.job!.doJob(person: character, game: self)
            } else {
                // Find a job
                await character.seekJob(startDate: generateDate(year: year),
                                        game: self)

                // If still no job then they might locate
                // TODO: Make this config driven rate
                if character.job == nil && Float.random(in: 0...1) < 0.05 {
                    var alltowns = availableLocations.filter({$0.type == .town}) as? Set<Town>

                    // Limit to towns where there is someone with the same affiliation
                    for town in alltowns ?? [] {
                        if persons.filter({!$0.affiliations.isDisjoint(with: character.affiliations) && $0.location == town}).count == 0 {
                            alltowns?.remove(town)
                        }
                    }

                    let newlocation = alltowns?.randomElement()
                    if newlocation != nil {
                        character.moves(to: newlocation!, family: true)
                    }
                }
            }
        }

        for character in persons where !character.resources.filter({$0.key.lifespan > 0}).isEmpty {
            // Age and expire resources
            for (resource, count) in character.resources where resource.lifespan > 0 {
                character.resources[resource] = nil
                resource.age += 1

                if resource.age <= resource.lifespan {
                    character.resources[resource] = count
                }
            }
        }
//        }
    }
    
    func tradeMatching(buyer: Person, count: Int = 1) {
        // Try to match-up wanted resources with those for sale
        var possibleMatches: [Resource] = []
        for (resource, number) in buyer.wantedResources {
            for character in persons where character.resources.keys.contains(where: {$0.forSale && $0.name == resource.name}) {
                possibleMatches.append(contentsOf: character.resources.keys.filter({$0.forSale}))
            }

            if possibleMatches.count > 0 {
                for _ in 1...count {
                    for _ in 1...number {
                        possibleMatches.randomElement()?.setMatchedBuyer(buyer)
                    }
                }
            }
        }

    }

    func makeTrades(buyer: Person, seller: Person? = nil) -> Bool {
        var bReturn = false
        for character in persons where character.resources.keys.contains(where: {$0.matchedBuyer == buyer}) {
            if seller != nil {
                if character != seller { continue }  // Explicit seller was set and this isn't it
            }
            
            for (resource, _) in character.resources.filter({$0.key.matchedBuyer == buyer}) {
                if let rate = resource.getExchRate() {
                    if rate.sellResource.countIgnoringAge(resources: buyer.resources) < Int(rate.rate) {
                        // Insufficient amount of resource to make trade, remove the buyer
                        resource.matchedBuyer = nil
                        return false
                    }
                    
                    for _ in (1...Int(rate.rate)) {
                        buyer.removeResource(resource: rate.sellResource)
                        var res = rate.sellResource.newInstance()
                        res.forSale = false
                        character.addResource(resource: res)
                    }
                    
                    
                    character.removeResource(resource: resource)
                    var res = resource.newInstance()
                    res.forSale = false
                    res.matchedBuyer = nil
                    buyer.addResource(resource: res)
                    bReturn = true
                }
            }
        }

        return bReturn
    }

    func generateBattleEvent(attacker: Affiliation) {
        let filter = self.availableAffiliations.filter({$0 != attacker})
        if filter.count == 0 { return }
        let triggerYr = self.year + 1
        let defender = filter.randomElement()!
        let name = "The Battle of " + (defender.capital?.name ?? "Nowhere")
        let desc = "The " + attacker.name + " tribe attacked the " + defender.name + " tribe"
        let killed = ConfigLoader.injuries.first(where: {$0.name == "Killed In Battle"})!
        var battle = Event(name: name, description: desc, triggerYear: triggerYr)
        battle.jobRelocation = [[attacker: [JobType.military: 0.5]]: defender.capital!]
        battle.injuriesAdded = [killed]
        battle.returnOnEnd = true

        // TODO: Randomise this to have longer battles
        battle.endYear = triggerYr

        ConfigLoader.events.insert(battle)
    }

    func generateLocationEvents() async {
        for location in ConfigLoader.locations where location.type == .town {
            let town = location as? Town
            if town != nil && (town?.founded ?? 0) > self.year {
                let eventName = town!.name + " founded"
                let eventDesc = "New town " + town!.name + " has been founded"
                var foundedEvent = Event(name: eventName, description: eventDesc, triggerYear: town!.founded)
                foundedEvent.locationsAdded = [location]
                ConfigLoader.events.insert(foundedEvent)
            }
            else
            {
                self.availableLocations.insert(location)
            }

            if town != nil && (town?.abandoned ?? 0) > self.year {
                let eventName = town!.name + " abandoned"
                let eventDesc = town!.name + " has been abandoned"
                var abandonEvent = Event(name: eventName, description: eventDesc, triggerYear: town!.abandoned ?? 0)
                abandonEvent.locationsRemoved = [location]
                ConfigLoader.events.insert(abandonEvent)
            }
            else if town?.abandoned != nil {
                self.availableLocations.remove(location)
            }

            if town != nil {
                // Work out who would be the current rulers of the town based on the year
                // defaulting to the founding group
                let curRulerIdx = town!.rulers.keys.filter({$0 <= self.year}).sorted(by: {$0 > $1}).first
                if curRulerIdx != nil {
                    town?.ruler = town?.rulers[curRulerIdx!]
                } else if town?.foundedBy != nil {
                    town?.ruler = town?.foundedBy
                }

            }
        }
    }

    func removeDeadCharacters() async {
        // Only remove characters who are not related to the player
        let gameD = getGameDate()
        let theDead = persons.filter({$0.dateOfDeath ?? gameD < gameD && $0.relatedToThePlayer == false})
        let theLiving = persons.subtracting(theDead)
        persons = theLiving

    }

    func getGameDate() -> Date {
        return generateDate(year: self.year, month: self.month, day: 1)
    }
    
    func getMaxDate() -> Date {
        return generateDate(year: 2999, month: 12, day: 31)
    }
    
    func getMinDate() -> Date {
        return generateDate(year: -4000, month: 1, day: 1)
    }

    func generateDate(year: Int, month: Int? = nil, day: Int? = nil) -> Date {
            var components: DateComponents

            if month == nil && day == nil {
                components = DateComponents(year: year, month: Int.random(in: 1...12), day: Int.random(in: 1...28))
            } else if month == nil {
                components = DateComponents(year: year, month: Int.random(in: 1...12), day: day!)
            } else if day == nil {
                components = DateComponents(year: year, month: month!, day: Int.random(in: 1...28))
            } else {
                components = DateComponents(year: year, month: month!, day: day!)
            }
            return calendar.date(from: components)!

    }
}

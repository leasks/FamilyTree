//
//  EventsTriggers.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 02/08/2023.
//

import XCTest
@testable import FamilyTree

final class EventsTriggers: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEventsAreActivated() async throws {
        //        Given the Black Death is a defined event
        //        When the year is between 1346 and 1353
        //        Then bubonic plague is part of the active injury list
        let illness: Injury = Injury(name: "Bubonic Plague", likelihood: 0.5)
        let blackDeath: Event = Event(name: "Black Death", description: "The Black Death was a ...", triggerYear: 1346, injuriesAdded: [illness])

        var game = GameEngine(year: 1345, month: 12)
        ConfigLoader.events.insert(blackDeath)

        await game.endTurn()

        let injuries = await game.availableInjuries
        XCTAssertTrue(injuries.contains(illness))
    }
    
    func testEventsAreDeactivated() async throws {
        //        Given the Black Death is a defined event
        //        When the year is after 1353
        //        Then bubonic plague is not on the active injury list
        let illness: Injury = Injury(name: "Bubonic Plague", likelihood: 0.5)
        let blackDeathStart: Event = Event(name: "Black Death", description: "The Black Death was a ...", triggerYear: 1351, injuriesAdded: [illness])
        let blackDeathEnd: Event = Event(name: "End of Black Death", description: "The Black Death was a ...", triggerYear: 1352, injuriesRemoved: [illness])

        var game = GameEngine(year: 1350, month: 12)
        ConfigLoader.events.insert(blackDeathStart)
        ConfigLoader.events.insert(blackDeathEnd)

        await game.endTurn()

        let injuries = await game.availableInjuries
        XCTAssertTrue(injuries.contains(illness))

        await game.endTurn()

        let injuries2 = await game.availableInjuries
        XCTAssertFalse(injuries2.contains(illness))

        //
        // TODO:       Given World War Two is a defined event
        //        When the year is between 1939 and 1945
        //        Then conscientious objector is on the active affiliations list
        //        And war is on the active injury list
    }
    
    func testRemovalOfNPCs() async throws {
        // Given the collapse of the Roman Empire is a defined event
        // When the year is 410AD
        // Then all Roman military units (Legionary, Centurion and Legate) are removed from the NPC list
        // And all Roman leadership units are removed from the NPC list
        var romancollapse = Event(name: "Collapse of Roman Empire", description: "Collapse of Roman Empire", triggerYear: 410)
        let legionary = Job(name: "Legionary")
        let centurion = Job(name: "Centurion")
        let legate = Job(name: "Legate")
        let random = Job(name: "Random")
        var addromans = Event(name: "Rome", description: "Rome", triggerYear: 409)
        let roman = Affiliation(name: "Roman")
        let newNPC = NewNPC(count: 100, minAge: 20, maxAge: 40, affiliation: roman, jobDistribution: ["Legionary":0.2,"Legate":0.2,"Centurion":0.2,"Random":0.4])
        addromans.jobsAdded = [legionary, centurion, legate, random]
        addromans.newNPC = [newNPC]
        romancollapse.jobsRemoved = [legionary, centurion, legate]
        romancollapse.removeNPC = ["Legionary": 1,"Centurion": 1,"Legate": 1]
        
        var game = GameEngine(year: 408, month: 1)
        ConfigLoader.events.insert(addromans)
        ConfigLoader.events.insert(romancollapse)
        ConfigLoader.loadAffiliations()
        ConfigLoader.loadNames()

        await game.endTurn()
        let persons1 = await game.persons
        XCTAssertGreaterThan(persons1.filter({$0.job == legate}).count, 0, "Legates have not been created")
        XCTAssertGreaterThan(persons1.filter({$0.job == legionary}).count, 0, "Legionary have not been created")
        XCTAssertGreaterThan(persons1.filter({$0.job == centurion}).count, 0, "Centurion have not been created")
        XCTAssertGreaterThan(persons1.filter({$0.job == random}).count, 0, "General population has not been created")

        await game.endTurn()

        let persons = await game.persons
        XCTAssertEqual(persons.filter({$0.job == legate}).count, 0, "Legates have been left in the population")
        XCTAssertEqual(persons.filter({$0.job == legionary}).count, 0, "Legionary have been left in the population")
        XCTAssertEqual(persons.filter({$0.job == centurion}).count, 0, "Centurion have been left in the population")
        XCTAssertGreaterThan(persons.filter({$0.job == random}).count, 0, "Removed general population by mistake")

    }

    func testGenerationOfEvents() async throws {
        // Given the tribes of Iceni and Atrebates exist
        // And they are located in Caistor St Edmund and Canterbury respectively
        // When an inter-tribe battle is generated and triggered for Iceni
        // Then either Iceni military units have moved to Canterbury
        // But their labourers stay where they are
        let warrior = Job(name: "Warrior", type: .military)
        let chariot = Job(name: "Chariot", type: .military)
        let labourer = Job(name: "Labourer", type: .general)

        let dummyCounty = County(name: "Dummy", region: Region(name: "Dummy"))
        let canterbury = Town(name: "Canterbury", founded: 0, county: dummyCounty)
        let caistor = Town(name: "Caistor St Edmund", founded: 0, county: dummyCounty)
        var iceni = Affiliation(name: "Iceni")
        iceni.capital = caistor
        var atrebates = Affiliation(name: "Atrebates")
        atrebates.capital = canterbury

        let newIceni = NewNPC(count: 50, minAge: 20, maxAge: 40, affiliation: iceni, jobDistribution: ["Warrior": 0.3, "Chariot": 0.2, "Labourer": 0.5])
        let newAtrebates = NewNPC(count: 50, minAge: 20, maxAge: 40, affiliation: atrebates, jobDistribution: ["Warrior": 0.3, "Chariot": 0.2, "Labourer": 0.5])

        var initialise = Event(name: "Initialisation", description: "Initialisation", triggerYear: 100)
        initialise.jobsAdded = [warrior, chariot, labourer]
        initialise.affiliationsAdded = [iceni, atrebates]
        initialise.newNPC = [newIceni, newAtrebates]

        var game = GameEngine(year: 100, month: 1)
        ConfigLoader.loadAffiliations()
        ConfigLoader.loadNames()
        ConfigLoader.loadInjuries()
        await initialise.apply(game: game)
        await game.generateBattleEvent(attacker: iceni)
        await game.endTurn()

        let events = ConfigLoader.events
        let persons = await game.persons
        XCTAssertTrue(events.count > 0, "Battle wasn't generated")
        XCTAssertTrue(persons.filter({$0.affiliations.contains(iceni) && $0.job?.type == .military}).contains(where: {$0.location == canterbury}),
                      "There are no Iceni military units in Canterbury")
        XCTAssertTrue(persons.filter({$0.affiliations.contains(iceni) && $0.job == labourer}).contains(where: {$0.location == caistor}), "The Labourers didn't stay in Caistor")

        // Given the tribes of Iceni and Atrebates are at war started by the Iceni
        // When the battle is over
        // Then the Iceni military units return to Caistor
        await game.endTurn()

        XCTAssertFalse(persons.filter({$0.affiliations.contains(iceni) && $0.job?.type == .military}).contains(where: {$0.location == canterbury}),
                      "There are Iceni military units still in Canterbury")
        
    }

    func testEventInjuries() async throws {
        // Given there are people with military jobs and trade jobs in two locations
        // And the "killed in battle" injury exists
        // And it will be activated by a war event to only affect people in the military
        // And it will only impact people in one location
        // When the war event happens
        // Then only people with military jobs in the one location will have been impacted by the injury
        let fighter = Job(name: "Fighter", type: .military)
        let tradesman = Job(name: "Tradesman", type: .trade)

        let location1 = Town(name: "Location1", founded: 100, county: County(name: "County", region: Region(name: "Region")))
        let location2 = Town(name: "Location2", founded: 100, county: County(name: "County", region: Region(name: "Region")))
        let location3 = Town(name: "Location3", founded: 100, county: County(name: "County", region: Region(name: "Region")))
        var game = GameEngine(year: 2020, month: 1)
        for _ in 1...10 {
            var personMilitary = await Person(name: "Soldier", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personMilitary.job = fighter
            personMilitary.location = location1

            var personTrade = await Person(name: "Public", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personTrade.job = tradesman
            personTrade.location = location1

            var personMilitary2 = await Person(name: "Soldier", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personMilitary2.job = fighter
            personMilitary2.location = location2

            var personTrade2 = await Person(name: "Public", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personTrade2.job = tradesman
            personTrade2.location = location2

            var personTrade3 = await Person(name: "Public", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personTrade3.job = tradesman
            personTrade3.location = location3

            await game.addPerson(person: personMilitary)
            await game.addPerson(person: personTrade)
            await game.addPerson(person: personMilitary2)
            await game.addPerson(person: personTrade2)
            await game.addPerson(person: personTrade3)
        }

        var rates = RateAgeRanges(rate: 1)
        var mortality = AgeBasedRates(rates: [rates], type: "Mortality")
        var killedInBattle = Injury(name: "Killed In Battle")
        killedInBattle.impactedJobs = [.military]
        killedInBattle.likelihood = 1
        killedInBattle.untreatedMortality = mortality
        var war = Event(name: "War", description: "What is it good for?", triggerYear: 2021)
        war.injuriesAdded = [killedInBattle]
        war.location = [location1]
        war.endYear = 2022
        ConfigLoader.events = [war]

        await game.endTurn()

        let injuried = await game.persons.filter({$0.injuries.contains(killedInBattle)})
        XCTAssertGreaterThan(injuried.count, 0, "Nobody was injured")
        for person in injuried {
            XCTAssertTrue(person.location == location1, "Someone outside of the war location got injured")
            XCTAssertTrue(person.job == fighter, "Someone not in the military got injured")
        }

        // Given the war event is already happening
        // When it spreads to a second location
        // Then military people in both the first and second location can be injured
        var war2 = Event(name: "War", description: "What is it good for?", triggerYear: 2022)
        war2.location = [location2]
        war2.injuriesAdded = [killedInBattle]
        war2.endYear = 2023
        ConfigLoader.events.insert(war2)
        for _ in 1...10 {
            var personMilitary = await Person(name: "Soldier", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personMilitary.job = fighter
            personMilitary.location = location1

            await game.addPerson(person: personMilitary)
        }

        await game.endTurn()

        let date2 = await game.generateDate(year: 2021, month: 12, day: 31)
        let injured2 = await game.persons.filter({$0.injuries.contains(killedInBattle) && ($0.dateOfDeath ?? date2) > date2})
        XCTAssertGreaterThan(injured2.count, 0, "Nobody was injured")
        for person in injured2 {
            XCTAssertTrue(person.location == location1 || person.location == location2, "Someone outside of the war location got injured")
            XCTAssertTrue(person.job == fighter, "Someone not in the military got injured")
        }

        // Given the war is active
        // When it stops in location 1
        // Then only people in location 2 will be injured
        for _ in 1...10 {
            var personMilitary = await Person(name: "Soldier", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personMilitary.job = fighter
            personMilitary.location = location1

            var personMilitary2 = await Person(name: "Soldier", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
            personMilitary2.job = fighter
            personMilitary2.location = location2
            await game.addPerson(person: personMilitary2)
        }

        await game.endTurn()

        let date3 = await game.generateDate(year: 2022, month: 12, day: 31)
        let injured3 = await game.persons.filter({$0.injuries.contains(killedInBattle) && ($0.dateOfDeath ?? date3) > date3})
        XCTAssertGreaterThan(injured3.count, 0, "Nobody was injured")
        for person in injured3 {
            XCTAssertTrue(person.location == location2, "Someone outside of the war location got injured: " + person.location!.name)
            XCTAssertTrue(person.job == fighter, "Someone not in the military got injured")
        }

    }

    func testConversionEvents() async {
        // Given Boudica's revolt happens in AD60-61
        // And will result in the formation of the Romano British affiliation
        // When it is AD 62
        // Then the Iceni, Trinovante and all South East and East Anglia tribes are also affiliated as Romano British
        //
        let roman = Affiliation(name: "Roman")
        let iceni = Affiliation(name: "Iceni")
        let trinovante = Affiliation(name: "Trinovante")
        var romanoBritish = Affiliation(name: "Romano British")
        romanoBritish.likedAffiliations = [roman]
        var boudica = Event(name: "Boudica's Revolt", description: "Boudica's Revolt", triggerYear: 60)
        boudica.endYear = 61
        boudica.affiliationsAdded = [romanoBritish]
        boudica.convertAffiliation[iceni] = romanoBritish
        boudica.convertAffiliation[trinovante] = romanoBritish

        let game = GameEngine(year: 59, month: 1)
        ConfigLoader.affiliations = [roman, iceni, trinovante, romanoBritish]
        ConfigLoader.events = [boudica]
        await game.addToSets(newAffiliations: [roman, iceni, trinovante])
        let birthdate = await game.generateDate(year: 60)
        for _ in 1...10 {
            for afil in [iceni, trinovante, roman] {
                let person1 = await Person(name: "Person", dateOfBirth: birthdate, gender: .male, game: game)
                person1.affiliations = [afil]
                await game.addPerson(person: person1)
            }
        }

        await game.endTurn()

        await game.endTurn()

        let availAffil = await game.availableAffiliations
        XCTAssertTrue(availAffil.contains(romanoBritish))

        for person in await game.persons.filter({$0.affiliations.contains(iceni) || $0.affiliations.contains(trinovante)}) {
            XCTAssertTrue(person.affiliations.contains(romanoBritish))
        }

        for person in await game.persons.filter({$0.affiliations.contains(roman)}) {
            XCTAssertFalse(person.affiliations.contains(romanoBritish))
        }
    }
}

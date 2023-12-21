//
//  GameTurns.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 02/08/2023.
//

import XCTest
@testable import FamilyTree

final class GameTurns: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameClockMovesOn() async throws {
        // Given the Game clock is set to January 1910
        // When the game turn ends
        // Then the Game clock moves to January 1911
        var game = GameEngine(year: 1910, month: 1)
        await game.endTurn()

        let year = await game.year
        XCTAssertEqual(year, 1911, "Year has not advanced correctly")
    }

    func testGameTurnTriggersNPCUpdates() async throws {
        // Given Albert is 120 years old
        // And the current life expectancy is 80
        // When the game turn ends
        // Then Albert is very very (almost 100%) likey to have died
        var game = GameEngine(year: 2000, month: 1)
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 1880, month: 1)
        let birthdate = calendar.date(from: components)!
        let albert = await Person(name: "Albert", dateOfBirth: birthdate, gender: Sex.male, game: game)

        await game.addPerson(person: albert)
        
        let lifeExpectancy = FlatRates(rate: 80)
        lifeExpectancy.type = "Life Expectancy"
        
        // Clear the rates here because we are manipulating them in the test
        ConfigLoader.rates.insert(lifeExpectancy)
        
        await game.endTurn()
        
        XCTAssertNotNil(albert.dateOfDeath, "Albert is still alive - but this could be the infinitely small possibility so not a guaranteed failure")
        
        // Given Danielle is 8 years old
        // And she has no injuries
        // And the current life expectancy is 80
        // When the game turn ends
        // Then she is very very (nearly 100%) likely to still be alive
        components = DateComponents(year: 1992, month: 1)
        let birthdate2 = calendar.date(from: components)!
        let danielle = await Person(name: "Danielle", dateOfBirth: birthdate2, gender: Sex.female, game: game)
        game = GameEngine(year: 2000, month: 1)
        await game.addPerson(person: danielle)

        await game.endTurn()
        
        XCTAssertNil(danielle.dateOfDeath, "Danielle didn't make it - but this could be the infinitely small possibility so not a guaranteed failure")
        
        // Given Joanna is 21 years old
        // And she is trying for a child
        // And the current fertilty rate for 21 year olds is 100%
        // When the game turn ends
        // Then she will have a child
        components = DateComponents(year: 1979, month: 1)
        let birthdate3 = calendar.date(from: components)!
        var joanna = await Person(name: "Joanna", dateOfBirth: birthdate3, gender: Sex.female, game: game)
        joanna.tryingForFamily = true
        game = GameEngine(year: 2000, month: 1)
        await game.addPerson(person: joanna)

        let fertility = AgeBasedRates(rates: [RateAgeRanges(startAge: 20, endAge: 22, rate: 1)])
        fertility.type = "Fertility"
        ConfigLoader.rates.insert(fertility)

        await game.endTurn()

        XCTAssertEqual(joanna.descendants.count, 1, "Joanna didn't have any children")
    }
    
    func testSimulateTheGame() async throws {

        let numberOfTurns = 43
        let game = GameEngine(year: 40, month: 1)

        ConfigLoader.load()
        await game.initGame()
        await game.endTurn()

        repeat {
            // Remove the dead npcs
            await game.removeDeadCharacters()
            // Display some details
            let npcs = await game.persons.count
            let males = await game.persons.filter({$0.gender == Sex.male}).count
            let dead = await game.persons.filter({$0.dateOfDeath != nil}).count
            await print("Game Year: \(game.year)")
            print("Total NPCs: \(npcs) Total Died: \(dead) Total Male: \(males) Total Female: \(npcs - males)")
            for location in ConfigLoader.locations.filter({$0.type == .town}).sorted(by: {$0.name < $1.name}) {
                for affiliation in ConfigLoader.affiliations {
                    let npcs = await game.persons.filter({$0.location == location && $0.affiliations.contains(affiliation) && $0.dateOfDeath == nil}).count
                    let lastYear = await game.generateDate(year: game.getYear() - 1, month: 12, day: 31)
                    let gameD = await game.generateDate(year: game.getYear() - 2, month: 12, day: 31)
                    let deadNpc = await game.persons.filter({$0.location == location && $0.affiliations.contains(affiliation) && ($0.dateOfDeath ?? gameD) > lastYear}).count
                    let bornNpc = await game.persons.filter({$0.location == location && $0.affiliations.contains(affiliation) && $0.dateOfBirth > gameD}).count
                    if npcs > 0 {
                        print(location.name + " - " + affiliation.name + ": " + String(npcs) + " Died: " + String(deadNpc) + " Born: " + String(bornNpc))
                    }
                }
            }

            await game.endTurn()
        } while await game.year < numberOfTurns

        for location in ConfigLoader.locations.filter({$0.type == .town}).sorted(by: {$0.name < $1.name}) {
            for affiliation in ConfigLoader.affiliations {
                let npcs = await game.persons.filter({$0.location == location && $0.affiliations.contains(affiliation) && $0.dateOfDeath == nil}).count
                if npcs > 0 {
                    print(location.name + " - " + affiliation.name + ": " + String(npcs))
                }
            }
        }

        for npc in await game.persons {
            print(npc.asDebugString())
        }

    }
    
    func testStartTheGame() async throws {
        var game = GameEngine(year: 0, month: 1)
        let events = ConfigLoader.events
        let persons = await game.persons
        XCTAssertNotEqual(events.count, 0, "No events loaded")
        XCTAssertNotEqual(ConfigLoader.names.count, 0, "No names loaded")
        XCTAssertNotEqual(ConfigLoader.rates.count, 0, "No rates loaded")
        XCTAssertNotEqual(persons.count, 0, "No people generated")
    }
    
    func testWhatDoesJSONLookLike() throws {
        var dist: [String: Int] = [:]
        dist["Sword"] = 5
        dist["Land"] = 1
        //var test: NewNPC = NewNPC(count: 10, minAge: 1, maxAge: 100, genderDistribution: dist)
        let encoded = try JSONEncoder().encode(dist)
        print(String(data: encoded, encoding: .utf8)!)

    }

    func testNPCsAreSeededWithNecessaryWealthAndResourcesForJobs() async throws {
        // Given to be a warrior you need a sword
        // When NPCs are created that are warriors
        // Then they all have swords in their resource list
        ConfigLoader.load()
        let game = GameEngine(year: 100, month: 1)
        let sword = Resource(name: "Sword")
        let warrior = Job(name: "Warrior", requiredResources: [sword])
        let npc1 = NewNPC(count: 10, minAge: 20, maxAge: 40, jobDistribution: ["Warrior":1])
        let event1 = Event(name: "Test Event", description: "Test Event", triggerYear: 101, jobsAdded: [warrior], newNPC: [npc1])

        await event1.apply(game: game)

        for person in await game.persons.filter({$0.job == warrior}) {
            XCTAssertGreaterThan(person.resources[sword] ?? 0, 0, "Warrior doesn't have a sword")
        }

        // Given to be a farmer you need the skill of animal husbandry
        // When NPCs are created that are farmers
        // Then they all have animal husbandry as a skill
        let husbandry = Skill(name: "Animal Husbandry", description: "Animal Husbandry")
        let farmer = Job(name: "Farmer", requiredSkills: [husbandry])
        let npc2 = NewNPC(count: 10, minAge: 20, maxAge: 40, jobDistribution: ["Farmer":1])
        let event2 = Event(name: "Test Event", description: "Test Event", triggerYear: 102, jobsAdded: [farmer], newNPC: [npc2])

        await event2.apply(game: game)

        for person in await game.persons.filter({$0.job == farmer}) {
            XCTAssertTrue(person.skills?.contains(husbandry) ?? false, "Farmer doesn't have a Animal Husbandry skill")
        }

        // Given to be a local administrator you need to be at the Decuriones social class
        // When NPCs are created that are local administrators
        // Then they all have enough wealth to set their social class to Decuriones
        let decuriones = await SocialClass(name: "Decuriones", startDate: game.getGameDate(), endDate: game.getGameDate(), wealth: 100)
        var localadmin = Job(name: "Local Administrator")
        localadmin.socialClass = decuriones
        ConfigLoader.socialClasses = [decuriones]
        let npc3 = NewNPC(count: 10, minAge: 20, maxAge: 40, jobDistribution: ["Local Administrator":1])
        let event3 = Event(name: "Test Event", description: "Test Event", triggerYear: 103, jobsAdded: [localadmin], newNPC: [npc3])

        await event3.apply(game: game)

        let gameD = await game.getGameDate()
        for person in await game.persons.filter({$0.job == localadmin}) {
            XCTAssertEqual(person.socialClass(date: gameD), decuriones, "Local Administrator isn't a Decuriones")
        }
    }

    func testConfigLoaded() throws {
        ConfigLoader.load()

        XCTAssertNotNil(ConfigLoader.affiliations, "No Affiliations loaded")
        XCTAssertNotNil(ConfigLoader.rates, "No Rates loaded")
        XCTAssertNotNil(ConfigLoader.locations, "No Locations loaded")
        XCTAssertNotNil(ConfigLoader.socialClasses, "No Social Classes loaded")
        XCTAssertNotNil(ConfigLoader.events, "No Events loaded")
        XCTAssertNotNil(ConfigLoader.injuries, "No Injuries loaded")
        XCTAssertNotNil(ConfigLoader.jobs, "No Jobs loaded")
        XCTAssertNotNil(ConfigLoader.names, "No Names loaded")
        XCTAssertNotNil(ConfigLoader.resources, "No Resources loaded")
    }
}

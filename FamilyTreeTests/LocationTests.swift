//
//  LocationTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 16/08/2023.
//

import XCTest
@testable import FamilyTree

final class LocationTests: XCTestCase {

    var game = GameEngine()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPeopleLocations() async throws {
        // Given Fred is currently in London
        // When he moves to Manchester
        // Then his location will be Manchester
        // And not London
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2000)
        let fred = await Person(name: "Fred", dateOfBirth: calendar.date(from: components)!, gender: Sex.male, game: game)
        let dummyRegion = Region(name: "Dummy")
        let dummyCounty = County(name: "Dummy", region: dummyRegion)
        let london = Town(name: "London", founded: 45, county: dummyCounty)
        let manchester = Town(name: "Manchester", founded: 100, county: dummyCounty)
        fred.location = london
        
        fred.moves(to: manchester)
        
        XCTAssertEqual(fred.location, manchester, "Fred didn't move")
        XCTAssertNotEqual(fred.location, london, "Fred is still in London")

        // Given Fred is currently in London
        // And he is married and has 2 children
        // And he will be moving with his family
        // When he moves to Manchester
        // Then his location will be Manchester
        // And so will his wife
        // And also his children
        let fredswife = await Person(name: "Fred's Wife", dateOfBirth: calendar.date(from: components)!, gender: Sex.female, game: game)
        let fredsson = await Person(name: "Fred's Son", dateOfBirth: calendar.date(from: components)!, gender: Sex.female, game: game)
        let fredsdaughter = await Person(name: "Fred's Daughter", dateOfBirth: calendar.date(from: components)!, gender: Sex.female, game: game)
        fred.marries(spouse: fredswife, game: game)
        await fredswife.hasChild(child: fredsson, game: game)
        await fredswife.hasChild(child: fredsdaughter, game: game)
        fred.location = london
        fredsson.location = london
        fredswife.location = london
        fredsdaughter.location = london

        fred.moves(to: manchester, family: true)

        XCTAssertEqual(fred.location, manchester, "Fred didn't move")
        XCTAssertEqual(fredswife.location, manchester, "Fred's wife didn't move")
        XCTAssertEqual(fredsson.location, manchester, "Fred's son didn't move")
        XCTAssertEqual(fredsdaughter.location, manchester, "Fred's daughter didn't move")

        // Given Fred is currently in London
        // And he is married and has 2 children
        // And he will not be moving with his family
        // When he moves to Manchester
        // Then his location will be Manchester
        // But his wife's location will be London
        // And also his children will be in London
        fred.location = london
        fredsson.location = london
        fredswife.location = london
        fredsdaughter.location = london

        fred.moves(to: manchester, family: false)

        XCTAssertEqual(fred.location, manchester, "Fred didn't move")
        XCTAssertEqual(fredswife.location, london, "Fred's wife did move")
        XCTAssertEqual(fredsson.location, london, "Fred's son did move")
        XCTAssertEqual(fredsdaughter.location, london, "Fred's daughter did move")

        // Given Fred is currently in London
        // And he is married and has 2 children
        // And he will be moving with his family
        // But his daughter lives in Liverpool
        // When he moves to Manchester
        // Then his location will be Manchester
        // And his wife's location will be Manchester
        // And his son will be in Manchester
        // But his daughter will remain in Liverpool
        let liverpool = Town(name: "Liverpool", founded: 1207, county: dummyCounty)
        fred.location = london
        fredsson.location = london
        fredswife.location = london
        fredsdaughter.location = liverpool

        fred.moves(to: manchester, family: true)

        XCTAssertEqual(fred.location, manchester, "Fred didn't move")
        XCTAssertEqual(fredswife.location, manchester, "Fred's wife didn't move")
        XCTAssertEqual(fredsson.location, manchester, "Fred's son didn't move")
        XCTAssertEqual(fredsdaughter.location, liverpool, "Fred's daughter did move")

    }
    
    func testEventLocations() async throws {
        // Given the Battle of Hastings happens in Hastings
        // And will introduce 1000 Normans in to the game
        // When the year becomes 1066
        // Then 1000 Normans are added and their location is set to Hastings
        var battleofhastings = Event(name: "Battle of Hastings", description: "Battle of Hastings", triggerYear: 1066)
        let normans = Affiliation(name: "Normans")
        let newNormans = NewNPC(count: 1000, minAge: 10, maxAge: 30, affiliation: normans)
        let dummyRegion = Region(name: "Dummy")
        let dummyCounty = County(name: "Dummy", region: dummyRegion)
        let hastings = Town(name: "Hastings", founded: 1000, county: dummyCounty)
        battleofhastings.newNPC = [newNormans]
        battleofhastings.location = [hastings]
        var encoded = try JSONEncoder().encode(battleofhastings)
        print(String(data: encoded, encoding: .utf8)!)

        game = GameEngine(year: 1065, month: 1)
        //game.persons = []
        ConfigLoader.events.insert(battleofhastings)
        await game.endTurn()

        let person = await game.persons.first
        
        XCTAssertEqual(person?.location, hastings, "Newly generated characters aren't in Hastings")
        
        // Given the Great Fire of London happens in London
        // And will add "killed in great fire" to the injury list with 100% mortality
        // When the year becomes 1666
        // Then the people whose cause of death is "killed in great fire" are all located in London
        // And no-one outside of London will have that cause of death
        var greatfire = Event(name: "Great Fire of London", description: "Great Fire of London", triggerYear: 1666)
        let londoners = Affiliation(name: "Cockney")
        let newNPC = NewNPC(count: 100, minAge: 10, maxAge: 30, affiliation: londoners)
        let london = Town(name: "London", founded: 45, county: dummyCounty)
        let rate1 = RateAgeRanges(rate: 1)
        let mortality = AgeBasedRates(rates: [rate1], type: "Mortality")
        let killedinfire = Injury(name: "Killed in Great Fire", likelihood: 0.5, untreatedMortality: mortality)
        greatfire.newNPC = [newNPC]
        greatfire.location = [london]
        greatfire.injuriesAdded = [killedinfire]
        encoded = try JSONEncoder().encode(greatfire)
        print(String(data: encoded, encoding: .utf8)!)

        game = GameEngine(year: 1665, month: 1)
        ConfigLoader.events.insert(greatfire)
        await game.endTurn()

        let personList = await game.persons
        XCTAssertGreaterThan(personList.filter({$0.causeOfDeath == "Killed in Great Fire"}).count, 0, "No one was killed by the fire")
        XCTAssertEqual(personList.filter({$0.causeOfDeath == "Killed in Great Fire"}).first?.location, london, "Someone killed by the fire wasn't in london")
        XCTAssertEqual(personList.filter({$0.causeOfDeath == "Killed in Great Fire" && $0.location != london}).count, 0, "People outside of London were killed")
        
        // Given WW2 Evacuation is an event where people  under the age of 16 in London are evacuated to Wales
        // When the year becomes 1940  (is this the right date?)
        // Then everyone under the age of 16's location from London should be changed to Wales
        // But people under the age of 16 elsewhere remain where they are
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 1930)
        var ww2evac = Event(name: "WW2 Evacuation", description: "WW2 Evacuation", triggerYear: 1940)
        let wales = Town(name: "Wales", founded: 0, county: dummyCounty)
        let liverpool = Town(name: "Liverpool", founded: 1207, county: dummyCounty)
        let evacuees: [Town: Int] = [london: 16]
        let relocation = [evacuees: wales]
        ww2evac.ageRelocation = relocation
        let rod = await Person(name: "Rod", dateOfBirth: calendar.date(from: components)!, gender: Sex.male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: calendar.date(from: components)!, gender: Sex.female, game: game)
        components = DateComponents(year: 1920)
        let freddy = await Person(name: "Freddy", dateOfBirth: calendar.date(from: components)!, gender: Sex.male, game: game)
        rod.location = london
        jane.location = liverpool
        freddy.location = london
        encoded = try JSONEncoder().encode(ww2evac)
        print(String(data: encoded, encoding: .utf8)!)

        game = GameEngine(year: 1939, month: 1)
        await game.addPerson(person: rod)
        await game.addPerson(person: jane)
        await game.addPerson(person: freddy)
        //GameEngine.getInstance().availableInjuries = []
        ConfigLoader.events.insert(ww2evac)
        await game.endTurn()
        
        XCTAssertEqual(rod.location, wales, "Rod wasn't evacuated")
        XCTAssertEqual(jane.location, liverpool, "Jane was evacuated but she should have stayed where she was")
        XCTAssertEqual(freddy.location, london, "Freddy was evacuated but he was too old")

        // Given the Blitz is an event impacting London, Manchester and Liverpool
        // And it introduces an injury of "killed in air raid" with 100% mortality
        // When the year becomes 1941 (is this the right date?)
        // Then people whose cause of death is "killed in air raid" are only located in London, Manchester and Liverpool
        // And no-one located in Wales has this cause of death
        let manchester = Town(name: "Manchester", founded: 40, county: dummyCounty)
        var blitz = Event(name: "The Blitz", description: "The Blitz", triggerYear: 1941)
        let airraid = Injury(name: "Killed in Air Raid", likelihood: 1, untreatedMortality: mortality)
        blitz.injuriesAdded = [airraid]
        blitz.location = [london, liverpool, manchester]
        let george = await Person(name: "George", dateOfBirth: calendar.date(from: components)!, gender: Sex.male, game: game)
        george.location = manchester
        encoded = try JSONEncoder().encode(blitz)
        print(String(data: encoded, encoding: .utf8)!)

        ConfigLoader.events.insert(blitz)
        await game.addPerson(person: george)
        await game.endTurn()
        
        XCTAssertNil(rod.dateOfDeath, "Rod died - might not be due to air raid though " + (rod.causeOfDeath ?? "Unspecified"))
        XCTAssertEqual(jane.causeOfDeath, "Killed in Air Raid", "Jane either didn't die or was killed by something else")
        XCTAssertEqual(freddy.causeOfDeath, "Killed in Air Raid", "Freddy either didn't die or was killed by something else")
        XCTAssertEqual(george.causeOfDeath, "Killed in Air Raid", "George either didn't die or was killed by something else")
    }
    
    func testNewLocationsAndAbandonment() async throws {
//        Given Liverpool is a place located in the county of Lancashire
//        And is in the North West Region
//        And is founded in 1207
//        When the year is 1206
//        Then Liverpool does not exist as an available location
        let northwest = Region(name: "North West England")
        let southeast = Region(name: "South East England")
        let lancashire = County(name: "Lancashire", region: northwest)
        let middlesex = County(name: "Middlesex", region: southeast)
        let manchester = Town(name: "Manchester", founded: 0, county: lancashire)
        let aff = Affiliation(name: "Mancuian")
        let cockney = Affiliation(name: "Cockney")
        let london = Town(name: "London", founded: 50, county: middlesex)
        let liverpool = Town(name: "Liverpool", founded: 1207, county: lancashire, foundedBy: aff)
        game = GameEngine(year: 1205, month: 1)

        for _ in 1...20 {
            let manc = await Person(name: "Manc", dateOfBirth: game.generateDate(year: 2020), gender: .male, game: game)
            manc.location = manchester
            manc.affiliations.insert(aff)
            await game.addPerson(person: manc)
            let londoner = await Person(name: "Londoner", dateOfBirth: game.generateDate(year: 2020), gender: .female, game: game)
            londoner.location = london
            londoner.affiliations.insert(cockney)
            await game.addPerson(person: londoner)
        }

        ConfigLoader.locations = [northwest, lancashire, liverpool, southeast, middlesex, manchester, london]
        await game.generateLocationEvents()
        await game.endTurn()

        var locations = await game.availableLocations
        XCTAssertFalse(locations.contains(liverpool), "Liverpool is available but it hasn't been founded")

        //        Given Liverpool is a place located in the county of Lancashire
        //        And is in the North West Region
        //        And is founded in 1207
        //        When the year is 1207
        //        Then people already In Lancashire/North West will relocate to Liverpool
        //        And it will exist as a location
        await game.endTurn()
        await game.endTurn()

        let locations2 = await game.availableLocations
        XCTAssertTrue(locations2.contains(liverpool), "Liverpool is not available but it has been founded")
        let population = await game.persons.filter({$0.location == liverpool})
        XCTAssertGreaterThan(population.count, 0, "Nobody located in Liverpool")
        XCTAssertGreaterThan(population.filter({$0.affiliations.contains(aff)}).count, 0, "The inhabitants aren't all from Manchester")
        XCTAssertEqual(population.filter({$0.affiliations.contains(cockney)}).count, 0, "Some Londoners relocated which wasn't expected")

        // Given the town of Disasterville will be raised to the ground in 1515
        // And it is located in Middlesex
        // When the year is 1515
        // Then Disasterville is no longer part of the available locations
        // And its inhabitants have relocated to other parts of the county
        game = GameEngine(year: 1514, month: 1)
        let disaster = Town(name: "DisasterVille", founded: 1000, county: middlesex, abandoned: 1515)
        for _ in 1...20 {
            let person = await Person(name: "Unlucky", dateOfBirth: game.generateDate(year: 2020), gender: .male, game: game)
            person.location = disaster
            await game.addPerson(person: person)
        }
        let originalInhabs = await game.persons.filter({$0.location == disaster})
        ConfigLoader.locations.insert(disaster)
        await game.addToSets(newLocations: [disaster])

        await game.generateLocationEvents()
        await game.endTurn()

        let locations3 = await game.availableLocations
        XCTAssertFalse(locations3.contains(disaster), "The town is still in the available locations list")
        for orig in originalInhabs {
            let town = orig.location as? Town
            XCTAssertEqual(town?.county, middlesex, "Someone relocated outside of the county")
            XCTAssertNotEqual(town, disaster, "Some people are still in the town")
        }
    }

    func testRulingGroup() async {
        // Given it is AD42
        // And Canterbury is controlled by the Cantiaci
        // And the Romans don't like the Cantiaci
        // And when Romans conquer a location they subjagate the ruling tribe
        // When the Romans start to take over
        // Then the killed in battle injury can occur in Canterbury
        var game = GameEngine(year: 42, month: 12)
        let cantiaci = Affiliation(name: "Cantiaci")
        var roman = Affiliation(name: "Roman")
        let romanoBritish = Affiliation(name: "Romano British")
        let killedInBattle = Injury(name: "Killed In Battle")
        roman.dislikedAffiliations = [cantiaci]
        roman.conversionAffiliation = "Romano British"
        var canterbury = Town(name: "Canterbury", founded: 0, county: County(name: "Kent", region: Region(name: "South East")))
        canterbury.foundedBy = cantiaci
        canterbury.ruler = cantiaci
        canterbury.rulers[43] = roman
        ConfigLoader.affiliations = [cantiaci, roman, romanoBritish]
        ConfigLoader.loadInjuries()
        await game.addToSets(newLocations: [canterbury])

        await game.endTurn()

        let injuries = await game.availableInjuries.filter({$0.location?.contains(canterbury) ?? false})
        XCTAssertTrue(injuries.contains(killedInBattle))



        // Given it is now AD44
        // When the Romans have fully taken over Canterbury
        // Then Canterbury is controlled by Romans
        // And the Cantiaci are converted to Romano British
        // And they no longer dislike the Romans
        // And the killed in battle injury no longer exists
        await game.endTurn()

        let injury2 = await game.availableInjuries.filter({$0.location?.contains(canterbury) ?? false})
        XCTAssertTrue(canterbury.ruler == roman)
        XCTAssertFalse(injury2.contains(killedInBattle))
        XCTAssertFalse(roman.dislikedAffiliations?.contains(cantiaci) ?? true)

        // Given it is AD45
        // And Silchester is controlled by the Atrebates
        // And the Romans like the Atrebates
        // When the Romans start to take over
        // Then it's not hostile and killed in battle injury is not added
        var silchester = Town(name: "silchester", founded: 0, county: County(name: "Random", region: Region(name: "Random")))
        let atrebates = Affiliation(name: "Atrebates")
        roman.likedAffiliations = [atrebates]
        silchester.ruler = atrebates
        silchester.rulers[45] = roman

        let injury3 = await game.availableInjuries.filter({$0.location?.contains(silchester) ?? false})
        XCTAssertFalse(injury3.contains(killedInBattle))

    }

    func testLocationInfrastructure() throws {
        // Given NewTown has just been founded
        // When looking at the list of built infrastructure
        // Then there are no public buildings
        let newTown = Town(name: "NewTown", founded: 0, county: County(name: "NewCounty", region: Region(name: "NewRegion")))

        XCTAssertTrue(newTown.infrastructure.count == 0, "Somehow NewTown has infrastructure")

        // TODO: Given the Roman legion are in NewTown
        // When they set-up camp
        // Then the infrastructure list includes barracks
        

        // TODO: Given NewTown is Roman owned
        // When there is an architect in NewTown (?? - possibly just dates when these things happen)
        // Then an Aqueduct is added to the infrastructure list
    }
}

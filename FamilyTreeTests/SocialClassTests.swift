//
//  SocialClassTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 09/10/2023.
//

import XCTest
@testable import FamilyTree

final class SocialClassTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJobsAndSocialClass() async throws {
        // Given being a local administrator requires you to be part of the local elite class
        // And Chris is not part of the local elite
        // When he tries to get a job
        // Then he is not able to become a local administrator
        let game = GameEngine(year: 2000, month: 1)
        var localElite = await SocialClass(name: "Local Elite", startDate: game.getMinDate(), endDate: game.getMaxDate())
        let chris = await Person(name: "Chris", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        var localAdmin = Job(name: "Local Administrator")
        localElite.wealth = 1
        localAdmin.socialClass = localElite
        ConfigLoader.socialClasses = [localElite]
        await game.addToSets(newJobs: [localAdmin])
        await game.addPerson(person: chris)

        await chris.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertNil(chris.job, "Chris somehow managed to get a job")

        // Given Chris has become part of the local elite
        // When he tries to get a job
        // Then he is allowed to be a local administrator
        let coin = Resource(name: "Coin")
        chris.resources[coin] = 5

        await chris.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertEqual(chris.job, localAdmin, "Chris was not able to become a local administrator")

        // Given being a farm hand requires no social class
        // And Jane is part of the Peregrini only
        // When she tries to get a job
        // Then she can become a farm hand
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 2000), gender: Sex.female, game: game)
        let farmHand = Job(name: "Farm Hand")
        await game.addToSets(newJobs: [farmHand])

        await jane.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertEqual(jane.job, farmHand, "Jane was not able to become a farm hand")

    }

    func testSocialMobility() async throws {
        let game = GameEngine(year: 2000, month: 1)

        // Given Barry is currently a Roman citizen
        // When he acquires a lot of wealth
        // Then his social class changes to Decuriones (local elite)
        let roman = Affiliation(name: "Roman")
        var decuriones = await SocialClass(name: "Decuriones", startDate: game.getMinDate(), endDate: game.getMaxDate())
        var citizen = await SocialClass(name: "Citizen", startDate: game.getMinDate(), endDate: game.getMaxDate())
        let peregrini = await SocialClass(name: "Peregrini", startDate: game.getMinDate(), endDate: game.getMaxDate())
        decuriones.affiliations = [roman]
        citizen.affiliations = [roman]
        let barry = await Person(name: "Barry", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        barry.affiliations = [roman]
        decuriones.wealth = 1000
        ConfigLoader.socialClasses = [peregrini, citizen, decuriones]

        let land = Resource(name: "Land")
        let coin = Resource(name: "Coin")
        let exchRate = ExchangeRate(rate: 2000, buyResource: land, sellResource: coin)
        ConfigLoader.rates = [exchRate]

        barry.resources[land] = 1

        let gameD = await game.getGameDate()
        XCTAssertEqual(barry.socialClass(date: gameD), decuriones, "Barry did not move up the social class hierarchy")

        // Given Anna is currently a Peregrini
        // When she marries Barry
        // Then her social class changes to Decuriones
        // And she gains Roman citizenship
        let anna = await Person(name: "Anna", dateOfBirth: game.generateDate(year: 2000), gender: Sex.female, game: game)

        anna.marries(spouse: barry, game: game)

        XCTAssertEqual(anna.socialClass(date: gameD), decuriones, "Anna did not move to Decuriones through marriage")
        XCTAssertTrue(anna.affiliations.contains(roman), "Anna did not gain Roman citizenship through marriage")

        // Given Barry is not very prudent with his money
        // When he loses it all
        // Then both he and Anna drop back doen to Roman citizens
        barry.resources.removeAll()

        XCTAssertEqual(barry.socialClass(date: gameD), citizen, "Barry did not move down to citizen")
        XCTAssertEqual(anna.socialClass(date: gameD), citizen, "Anna did not move down to citizen")

    }

    func testKeepingItInTheSocialClass() async throws {
        // Given Dave is part of the upper class
        // And Jane is part of the lower class
        // And marriage is kept within class
        // When Dave looks to marry
        // Then he does not marry Jane
        let game = GameEngine(year: 1900, month: 1)
        let upper = await SocialClass(name: "Upper Class", startDate: game.getMinDate(), endDate: game.getMaxDate(), wealth: 50)
        let lower = await SocialClass(name: "Lower Class", startDate: game.getMinDate(), endDate: game.getMaxDate())
        let coin = Resource(name: "Coin")

        let rate = FlatRates(rate: 1, type: "Class Mixing")
        ConfigLoader.rates = [rate]
        ConfigLoader.socialClasses = [upper, lower]

        let dave = await Person(name: "Dave", dateOfBirth: game.generateDate(year: 1880), gender: .male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 1880), gender: .female, game: game)
        dave.resources[coin] = 60
        await game.addPerson(person: dave)
        await game.addPerson(person: jane)

        await dave.marries(game: game)

        XCTAssertNil(dave.spouse, "Dave got married")

        // Given Jane is now part of the upper classes
        // When Dave looks to marry
        // Then he does marry Jane
        jane.resources[coin] = 80

        await dave.marries(game: game)

        XCTAssertEqual(dave.spouse, jane, "Dave didn't marry Jane")
    }

}

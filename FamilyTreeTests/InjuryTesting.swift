//
//  InjuryTesting.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 04/10/2023.
//

import XCTest
@testable import FamilyTree

final class InjuryTesting: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDepletingHealth() async throws {
        // Given John's Health is currently at 100%
        // And having poor health at his age has a mortality of 10%
        // When John has poor health
        // Then his overall Health drops by up to 10%
        let game = GameEngine(year: 2000, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 1980), gender: Sex.male, game: game)
        let mortality = RateAgeRanges(endAge: 21, rate: 0.1)
        let mortality2 = RateAgeRanges(startAge: 21, rate: 0.9)
        let poorHealth = Injury(name: "Poor Health", untreatedMortality: AgeBasedRates(rates: [mortality, mortality2], type: "Mortality"))
        john.injuries.insert(poorHealth)
        Task {
            await game.addToSets(newInjuries: [poorHealth])
            await game.addPerson(person: john)

            await game.endTurn()

            var person = await game.persons.first(where: {$0.name == "John"})
            XCTAssertGreaterThanOrEqual(person!.health, 0.9, "John's health is not greater than 90%")
            XCTAssertLessThan(person!.health, 1, "John's health is still 100%")

            // Given John's Health is currently at 0.1%
            // And having poor health at his age has a mortality of 90%
            // When John has poor health
            // Then his overall Health is very very likely to now be 0%
            // And he is dead
            john.health = 0.001

            await game.endTurn()

            person = await game.persons.first(where: {$0.name == "John"})
            XCTAssertEqual(person?.health, 0, "John's health is not 0% - maybe a very small chance this could happen")
            XCTAssertNotNil(person?.dateOfDeath, "John is still alive")

            // Given Dave's Health is currently 100%
            // And being killed in battle has a 100% mortality rate (so is fatal)
            // When Dave is killed in battle
            // Then his health drops to 0%
            // And he is dead
            let dave = await Person(name: "Dave", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
            let death = RateAgeRanges(rate: 1)
            let killedInBattle = Injury(name: "Killed in Battle", untreatedMortality: AgeBasedRates(rates: [death], type: "Mortality"))
            dave.injuries.insert(killedInBattle)
            await game.addToSets(newInjuries: [killedInBattle])
            await game.addPerson(person: dave)

            await game.endTurn()

            person = await game.persons.first(where: {$0.name == "Dave"})
            XCTAssertEqual(person?.health, 0, "Dave's health is not 0% - maybe a very small chance this could happen")
            XCTAssertNotNil(person?.dateOfDeath, "Dave is still alive")
        }

    }

    func testGettingTreated() async throws {
        // Given Fred has a war wound that is untreated
        // And it's mortality is 5%
        // And his current health is 75%
        // When he gets treated
        // Then he no longer has a war wound
        // And his health remains at 75%
        let game = GameEngine(year: 2000, month: 1)
        let fred = await Person(name: "Fred", dateOfBirth: game.generateDate(year: 1980), gender: Sex.male, game: game)
        let mortality = RateAgeRanges(rate: 0.05)
        var warWound = Injury(name: "War Wound", untreatedMortality: AgeBasedRates(rates: [mortality], type: "Mortality"))
        fred.injuries.insert(warWound)
        fred.health = 0.75
        await game.addPerson(person: fred)

        fred.treatInjuries()
        await game.endTurn()

        XCTAssertEqual(fred.health, 0.75, "Fred's health has changed")
        XCTAssertFalse(fred.injuries.contains(warWound), "Fred still has untreated war wounds")
        XCTAssertTrue(fred.treatedInjuries.contains(warWound), "Fred still has untreated war wounds")

        // Given Fred has a war wound that is untreated
        // And he is in a location without a hospital
        // And the treatment for war wounds is to go to hospital
        // When he looks for treatment
        // Then it will not be treated
        let cure = await Cure(startDate: game.generateDate(year: 1900), location: Location(name: "Hospital"))
        warWound.cure = cure
        fred.treatedInjuries = []
        fred.injuries.insert(warWound)

        fred.treatInjuries()
        XCTAssertTrue(fred.injuries.contains(warWound), "Fred has been treated for war wounds")
        XCTAssertFalse(fred.treatedInjuries.contains(warWound), "Fred was treated for war wounds")

    }

    func testJobImpacts() throws {
        // TODO: Given Bert has an agricultural job
        // And Ernie has a clerical job
        // And Poor Health for agricultural jobs has a 20% mortality
        // And Poor Health for clerical jobs has a 5% mortality (as they are in towns with aqueducts)
        // When both of them suffer from poor health
        // Then Ernie's mortality rate is 5%
        // And Bert's is 20%

        // TODO: Given Bert has poor health
        // When he moves job to a town-based job
        // Then the mortality of poor health drops to 5% for him
    }
}

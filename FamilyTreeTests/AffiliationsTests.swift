//
//  AffiliationsTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 21/08/2023.
//

import XCTest
@testable import FamilyTree

final class AffiliationsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAffiliations() async throws {
        // Given Joanna is a Celt
        // And Fred is a Roman
        // And Dave is a Norman
        // And Celts do not like Normans
        // But have no opinion on Romans
        // When Joanna is looking to marry
        // Then she can marry Fred
        // But won't marry Dave
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2000)
        let dateOfBirth = calendar.date(from: components)!
        var game = GameEngine(year: 2020, month: 1)
        let joanna = await Person(name: "Joanna", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        let fred = await Person(name: "Fred", dateOfBirth: dateOfBirth, gender: Sex.male, game: game)
        let dave = await Person(name: "Dave", dateOfBirth: dateOfBirth, gender: Sex.male, game: game)
        let norman = Affiliation(name: "Norman")
        var celtic = Affiliation(name: "Celtic")
        celtic.dislikedAffiliations = [norman]
        let roman = Affiliation(name: "Roman")
        
        joanna.affiliations = [celtic]
        dave.affiliations = [norman]
        fred.affiliations = [roman]

        for person in [joanna, dave, fred] {
            await game.addPerson(person: person)
        }

        await joanna.marries(game: game)
        
        XCTAssertTrue(joanna.spouse == fred, "Joanna didn't marry Fred - but it may just be because of random nature")
        XCTAssertFalse(joanna.spouse == dave, "Joanna married Dave but she doesn't like Normans")
    }

}

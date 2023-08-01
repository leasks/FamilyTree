//
//  CharacterDies.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import XCTest
@testable import FamilyTree

final class CharacterDies: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameEndsWhenNoDescendants() throws {
        // Given I have no descendants
        // When I die
        // Then the game is over
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let me: Person = Person(name: "Stephen", dateOfBirth: formatter.date(from: "09/10/1976")!, gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: me)
        me.dies()

        XCTAssertFalse(GameEngine.getInstance().active(), "Game is not over when it should be")

    }

    func testGameContinuesWhenAtLeastOneDescendant() throws {
        // Given I have at least one descendant
        // When I die
        // Then the game is not over
        // TODO: And I can choose which descendant I will continue as
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let me: Person = Person(name: "Stephen", dateOfBirth: formatter.date(from: "09/10/1976")!, gender: Sex.male, location: Location())
        let child: Person = Person(name: "Bella", dateOfBirth: formatter.date(from: "04/04/2010")!, gender: Sex.female, location: Location())

        GameEngine.getInstance().setActivePerson(person: me)
        me.descendants.insert(child)
        me.dies()

        XCTAssertTrue(GameEngine.getInstance().active(), "Game is over but it should be active")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

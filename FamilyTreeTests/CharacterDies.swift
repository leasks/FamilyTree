//
//  CharacterDies.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import XCTest
@testable import FamilyTree

final class CharacterDies: XCTestCase {
    let game = GameEngine(year: 2020, month: 1)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameEndsWhenNoDescendants() async throws {
        // Given I have no descendants
        // When I die
        // Then the game is over
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let me: Person = await Person(name: "Stephen", dateOfBirth: formatter.date(from: "09/10/1976")!, gender: Sex.male, game: game)

        await game.setActivePerson(person: me)
        await me.dies(game: game)

        let active = await game.active()
        XCTAssertFalse(active, "Game is not over when it should be")

    }

    func testGameContinuesWhenAtLeastOneDescendant() async throws {
        // Given I have at least one descendant
        // When I die
        // Then the game is not over
        // TODO: And I can choose which descendant I will continue as
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let me: Person = await Person(name: "Stephen", dateOfBirth: formatter.date(from: "09/10/1976")!, gender: Sex.male, game: game)
        let child: Person = await Person(name: "Bella", dateOfBirth: formatter.date(from: "04/04/2010")!, gender: Sex.female, game: game)

        await game.setActivePerson(person: me)
        me.descendants.insert(child)
        await me.dies(game: game)

        let active = await game.active()
        XCTAssertTrue(active, "Game is over but it should be active")
    }

    func testInheritance() async throws {
        // Given John is married with children
        // And John has 100 coins
        // And inheritance is to the eldest son
        // When John dies
        // Then his son inherits all the coins
        // And his wife inherits nothing
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
        let wife = await Person(name: "Wife", dateOfBirth: game.generateDate(year: 2000), gender: .female, game: game)
        let son1 = await Person(name: "Son", dateOfBirth: game.generateDate(year: 2010), gender: .male, game: game)
        let daughter1 = await Person(name: "Daughter", dateOfBirth: game.generateDate(year: 2009), gender: .female, game: game)
        john.marries(spouse: wife, game: game)
        await john.hasChild(child: son1, game: game)
        await john.hasChild(child: daughter1, game: game)
        let coin = Resource(name: "Coin")
        john.resources[coin] = 100

        await john.dies(game: game)

        XCTAssertTrue(son1.resources[coin] ?? 0 == 100, "Son didn't inherit the coins")
        XCTAssertTrue(wife.resources[coin] ?? 0 == 0, "Wife inherited some coin")

        // Given John is married with children
        // And John has 100 coins
        // And inheritance is fair
        // When John dies
        // Then his wife inherits all the coins
        // And his children inherits nothing
        john.dateOfDeath = nil
        john.causeOfDeath = nil
        son1.resources[coin] = 0
        john.resources[coin] = 100

        await john.dies(game: game, fairInheritance: true)

        XCTAssertTrue(son1.resources[coin] ?? 0 == 0, "Son did inherit the coins")
        XCTAssertTrue(wife.resources[coin] ?? 0 == 100, "Wife didn't inherit some coin")

        // Given John has 2 children, 1 girl and 1 boy
        // And his wife has died
        // And John has 100 coins
        // And inheritance is only to the eldest boy
        // When John dies
        // Then his son inherits all his coins
        john.dateOfDeath = nil
        john.causeOfDeath = nil
        wife.dateOfDeath = await game.generateDate(year: 2020)
        wife.resources[coin] = 0
        john.resources[coin] = 100

        await john.dies(game: game)

        XCTAssertTrue(son1.resources[coin] ?? 0 == 100, "Son didn't inherit the coins")
        XCTAssertTrue(daughter1.resources[coin] ?? 0 == 0, "Daughter did inherit some coin")

        // Given John has 2 children, both boys
        // And John has 100 coins
        // And inheritance is only to the eldest boy
        // When John dies
        // Then his eldest son inherits all his coins
        john.dateOfDeath = nil
        john.causeOfDeath = nil
        son1.resources[coin] = 0
        john.resources[coin] = 100
        var son2 = await Person(name: "Son2", dateOfBirth: game.generateDate(year: 2015), gender: .male, game: game)
        await john.hasChild(child: son2, game: game)

        await john.dies(game: game)

        XCTAssertTrue(son1.resources[coin] ?? 0 == 100, "Eldest Son didn't inherit the coins")
        XCTAssertTrue(son2.resources[coin] ?? 0 == 0, "Youngest Son did inherit some coin")

        // Given John has 3 children
        // And John has 120 coins
        // And inheritance is fair
        // When John dies
        // Then both his children inherit 40 coins each
        john.dateOfDeath = nil
        john.causeOfDeath = nil
        son1.resources[coin] = 0
        john.resources[coin] = 120

        await john.dies(game: game, fairInheritance: true)

        XCTAssertTrue(son1.resources[coin] ?? 0 == 40, "Eldest Son didn't inherit the coins")
        XCTAssertTrue(son2.resources[coin] ?? 0 == 40, "Youngest Son didn't inherit some coin")
        XCTAssertTrue(daughter1.resources[coin] ?? 0 == 40, "Daughter didn't inherit some coin")
    }

}

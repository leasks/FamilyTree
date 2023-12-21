//
//  RatesTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 31/07/2023.
//

import XCTest
@testable import FamilyTree

final class RatesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAgeBasedRates() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        var game = GameEngine(year: 1970, month: 1)
        let jane: Person = await Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                        gender: Sex.female, game: game)

        await game.setActivePerson(person: jane)
        
        let range1: RateAgeRanges = RateAgeRanges(startAge: 19, endAge: 26, rate: 0.92)
        let range2: RateAgeRanges = RateAgeRanges(startAge: 27, endAge: 29, rate: 0.87)
        let range3: RateAgeRanges = RateAgeRanges(startAge: 30, endAge: 34, rate: 0.86)

        let rates: AgeBasedRates = AgeBasedRates(rates: [range1, range2, range3])

        // Set the game date to different points and check the returned rate
        game = GameEngine(year: 2000, month: 1)
        XCTAssertEqual(rates.getRate(person: jane), range1.rate, "Does not match first age range rate")
        game = GameEngine(year: 2006, month: 1)
        XCTAssertEqual(rates.getRate(person: jane), range2.rate, "Does not match second age range rate")
        game = GameEngine(year: 20110, month: 1)
        XCTAssertEqual(rates.getRate(person: jane), range3.rate, "Does not match third age range rate")
        game = GameEngine(year: 2023, month: 1)
        XCTAssertEqual(rates.getRate(person: jane), 0, "Does not match first age range rate")

    }

    func testLoadRates() async throws {
        XCTAssertGreaterThanOrEqual(ConfigLoader.rates.count, 1)
    }
        
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

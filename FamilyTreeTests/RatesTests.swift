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
        GameEngine.getInstance().reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAgeBasedRates() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let jane: Person = Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, location: Location())

        GameEngine.getInstance().setActivePerson(person: jane)
        
        let range1: RateAgeRanges = RateAgeRanges(startAge: 19, endAge: 26, rate: 0.92)
        let range2: RateAgeRanges = RateAgeRanges(startAge: 27, endAge: 29, rate: 0.87)
        let range3: RateAgeRanges = RateAgeRanges(startAge: 30, endAge: 34, rate: 0.86)

        let rates: AgeBasedRates = AgeBasedRates()
        rates.rates = [range1, range2, range3]

        // Set the game date to different points and check the returned rate
        GameEngine.getInstance().year = 2000
        XCTAssertEqual(rates.getRate(person: jane), range1.rate, "Does not match first age range rate")
        GameEngine.getInstance().year = 2006
        XCTAssertEqual(rates.getRate(person: jane), range2.rate, "Does not match second age range rate")
        GameEngine.getInstance().year = 2010
        XCTAssertEqual(rates.getRate(person: jane), range3.rate, "Does not match third age range rate")
        GameEngine.getInstance().year = 2023
        XCTAssertEqual(rates.getRate(person: jane), 0, "Does not match first age range rate")

    }

    func testLoadRates() throws {
        XCTAssertGreaterThanOrEqual(GameEngine.getInstance().rates.count, 1)
    }
    
    func testCreatePeople() throws {
        let people = Int.random(in: 20...40)
        var persons: Set<Person>
        let calendar = Calendar(identifier: .gregorian)

        for _ in (1...people) {
            let name = GameEngine.getInstance().names.filter({$0.gender == (Bool.random() ? "female" : "male")}).randomElement()!
            let components = DateComponents(year: GameEngine.getInstance().year - Int.random(in: 1...40), month: Int.random(in: 1...12))

            var peep: Person = Person(name: name.name, dateOfBirth: calendar.date(from: components)!, gender: name.gender == "male" ? Sex.male : Sex.female, location: Location())
            print (peep.name + " \(peep.gender) " + peep.age().description)
        }
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

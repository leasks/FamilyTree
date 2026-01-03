//
//  StarvationAndTaxationTests.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 28/05/2024.
//

import XCTest
@testable import FamilyTree

final class StarvationAndTaxationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFoodIsNeededEveryYear() async throws {
        // Scenario: Food is needed every year
        // Given John has no food resource
        // When the game advances by 1 year
        // Then John has starvation as an injury
        // And his health decreases
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil, 
                                impactedJobs: nil, location: nil, likelihood: 1.0, 
                                untreatedMortality: nil, treatedMortality: nil)
        await game.addToSets(newInjuries: [starvation])
        
        let initialHealth = john.health
        
        // John has no food resource (default state)
        XCTAssertEqual(john.resources.count, 0, "John should have no resources initially")
        
        await game.endTurn()
        
        XCTAssertTrue(john.injuries.contains(starvation), "John should have starvation as an injury")
        XCTAssertLessThan(john.health, initialHealth, "John's health should decrease")
    }
    
    func testAcquiringFoodRemovesStarvation() async throws {
        // Scenario: Acquiring food removes starvation
        // Given John has starvation as an injury
        // And he has now found food as a resource
        // When the game advances by 1 year
        // Then John no longer has starvation
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil,
                                impactedJobs: nil, location: nil, likelihood: 1.0,
                                untreatedMortality: nil, treatedMortality: nil)
        let food = Resource(name: "Food")
        await game.addToSets(newInjuries: [starvation])
        
        // John has starvation
        john.injuries.insert(starvation)
        
        // John has now found food
        john.addResource(resource: food)
        
        await game.endTurn()
        
        XCTAssertFalse(john.injuries.contains(starvation), "John should no longer have starvation")
    }
    
    func testFoodCanBeSharedWithSpouse() async throws {
        // Scenario: Food can be shared with your spouse
        // Given John has 2 food resources
        // And he is married to Jane
        // And Jane has no food resources
        // When the game advances by 1 year
        // Then neither John nor Jane are starving
        // And John now has 0 food resources
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 2000), gender: Sex.female, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil,
                                impactedJobs: nil, location: nil, likelihood: 1.0,
                                untreatedMortality: nil, treatedMortality: nil)
        let food = Resource(name: "Food")
        await game.addToSets(newInjuries: [starvation])
        
        // John has 2 food resources
        john.addResource(resource: food)
        john.addResource(resource: food)
        
        // John and Jane are married
        john.spouse = jane
        jane.spouse = john
        john.dateOfMarriage = game.getGameDate()
        jane.dateOfMarriage = game.getGameDate()
        
        await game.endTurn()
        
        XCTAssertFalse(john.injuries.contains(starvation), "John should not be starving")
        XCTAssertFalse(jane.injuries.contains(starvation), "Jane should not be starving")
        XCTAssertEqual(food.countIgnoringAge(resources: john.resources), 0, "John should have 0 food resources")
    }
    
    func testFoodCanBeSharedWithChildren() async throws {
        // Scenario: Food can be shared with children
        // Given John has 4 food resources (note: typo in feature file says 'resourcea')
        // And he is married to Jane who has 0 food
        // And he has 2 children who also have 0 food
        // When the game advances by 1 year
        // Then none of John, Jane or the children are starving
        // And John now has 0 food resources
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 1990), gender: Sex.male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 1990), gender: Sex.female, game: game)
        let child1 = await Person(name: "Child1", dateOfBirth: game.generateDate(year: 2010), gender: Sex.male, game: game)
        let child2 = await Person(name: "Child2", dateOfBirth: game.generateDate(year: 2012), gender: Sex.female, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil,
                                impactedJobs: nil, location: nil, likelihood: 1.0,
                                untreatedMortality: nil, treatedMortality: nil)
        let food = Resource(name: "Food")
        await game.addToSets(newInjuries: [starvation])
        
        // John has 4 food resources
        for _ in 1...4 {
            john.addResource(resource: food)
        }
        
        // John and Jane are married
        john.spouse = jane
        jane.spouse = john
        john.dateOfMarriage = game.getGameDate()
        jane.dateOfMarriage = game.getGameDate()
        
        // They have 2 children
        await john.hasChild(child: child1, game: game)
        await john.hasChild(child: child2, game: game)
        
        await game.endTurn()
        
        XCTAssertFalse(john.injuries.contains(starvation), "John should not be starving")
        XCTAssertFalse(jane.injuries.contains(starvation), "Jane should not be starving")
        XCTAssertFalse(child1.injuries.contains(starvation), "Child1 should not be starving")
        XCTAssertFalse(child2.injuries.contains(starvation), "Child2 should not be starving")
        XCTAssertEqual(food.countIgnoringAge(resources: john.resources), 0, "John should have 0 food resources")
    }
    
    func testChildrenWillBePrioritisedForFood() async throws {
        // Scenario: Children will be prioritised for food
        // Given John has 2 food resources (note: typo in feature file says 'resourcea')
        // And he is married to Jane who has 0 food
        // And he has 2 children who also have 0 food
        // When the game advances by 1 year
        // Then neither of the children are starving
        // But John and Jane are starving
        // And John now has 0 food resources
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 1990), gender: Sex.male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 1990), gender: Sex.female, game: game)
        let child1 = await Person(name: "Child1", dateOfBirth: game.generateDate(year: 2010), gender: Sex.male, game: game)
        let child2 = await Person(name: "Child2", dateOfBirth: game.generateDate(year: 2012), gender: Sex.female, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil,
                                impactedJobs: nil, location: nil, likelihood: 1.0,
                                untreatedMortality: nil, treatedMortality: nil)
        let food = Resource(name: "Food")
        await game.addToSets(newInjuries: [starvation])
        
        // John has 2 food resources
        john.addResource(resource: food)
        john.addResource(resource: food)
        
        // John and Jane are married
        john.spouse = jane
        jane.spouse = john
        john.dateOfMarriage = game.getGameDate()
        jane.dateOfMarriage = game.getGameDate()
        
        // They have 2 children
        await john.hasChild(child: child1, game: game)
        await john.hasChild(child: child2, game: game)
        
        await game.endTurn()
        
        XCTAssertFalse(child1.injuries.contains(starvation), "Child1 should not be starving")
        XCTAssertFalse(child2.injuries.contains(starvation), "Child2 should not be starving")
        XCTAssertTrue(john.injuries.contains(starvation), "John should be starving")
        XCTAssertTrue(jane.injuries.contains(starvation), "Jane should be starving")
        XCTAssertEqual(food.countIgnoringAge(resources: john.resources), 0, "John should have 0 food resources")
    }
    
    func testYoungestChildWillBePrioritisedForFood() async throws {
        // Scenario: The youngest child will be prioritised for food
        // Given John has 1 food resource (note: typo in feature file says 'resourcea')
        // And he is married to Jane who has 0 food
        // And he has 2 children who also have 0 food
        // When the game advances by 1 year
        // Then the youngest child is not starving
        // But John and Jane are starving
        // And the eldest child is starving
        // And John now has 0 food resources
        
        let game = GameEngine(year: 2020, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 1990), gender: Sex.male, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: game.generateDate(year: 1990), gender: Sex.female, game: game)
        let eldestChild = await Person(name: "EldestChild", dateOfBirth: game.generateDate(year: 2010), gender: Sex.male, game: game)
        let youngestChild = await Person(name: "YoungestChild", dateOfBirth: game.generateDate(year: 2015), gender: Sex.female, game: game)
        let starvation = Injury(name: "Starvation", description: "Lack of food", cure: nil,
                                impactedJobs: nil, location: nil, likelihood: 1.0,
                                untreatedMortality: nil, treatedMortality: nil)
        let food = Resource(name: "Food")
        await game.addToSets(newInjuries: [starvation])
        
        // John has 1 food resource
        john.addResource(resource: food)
        
        // John and Jane are married
        john.spouse = jane
        jane.spouse = john
        john.dateOfMarriage = game.getGameDate()
        jane.dateOfMarriage = game.getGameDate()
        
        // They have 2 children
        await john.hasChild(child: eldestChild, game: game)
        await john.hasChild(child: youngestChild, game: game)
        
        await game.endTurn()
        
        XCTAssertFalse(youngestChild.injuries.contains(starvation), "Youngest child should not be starving")
        XCTAssertTrue(john.injuries.contains(starvation), "John should be starving")
        XCTAssertTrue(jane.injuries.contains(starvation), "Jane should be starving")
        XCTAssertTrue(eldestChild.injuries.contains(starvation), "Eldest child should be starving")
        XCTAssertEqual(food.countIgnoringAge(resources: john.resources), 0, "John should have 0 food resources")
    }

}

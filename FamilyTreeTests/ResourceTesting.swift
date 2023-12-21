//
//  ResourceTesting.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 27/08/2023.
//

import XCTest
@testable import FamilyTree

final class ResourceTesting: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJobResources() async throws {
        // Given becoming a warrior requires a sword
        // And John does not have a sword
        // When he looks for a job
        // Then he has to remain unemployed
        var game = GameEngine(year: 2020, month: 1)
        let sword = Resource(name: "Sword")
        let warrior = Job(name: "Warrior", requiredResources: [sword])
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [warrior])
        
        await john.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertNotEqual(john.job, warrior, "John managed to become a warrior")
        
        // Given John has now obtained a sword
        // When he looks for a job
        // Then he can become a warrior
        john.addResource(resource: sword)
        await john.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertEqual(john.job, warrior, "John didn't become a warrior despite having a sword")
    }
    
    func testCreatingAndTradingResources() async throws {
        // Given Dave is an Iron Smith
        // And Iron Smith's produce 10 swords a year
        // When the year ticks over
        // Then Dave now possess 10 swords
        var game = GameEngine(year: 2020, month: 1)
        let sword = Resource(name: "Sword")
        let ironsmith = Job(name: "Iron Smith", produceResource: [sword: 10])
        let dave = await Person(name: "Dave", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        dave.job = ironsmith
        await game.addPerson(person: dave)

        await game.endTurn()

        XCTAssertEqual(dave.resources.keys.filter({$0 == sword}).count, 10, "Dave didn't create ten swords")

        // Given Dave wants to sell a sword
        // And Bert wants to buy a sword
        // When trading happens
        // Then they are matched for the trade
        let bert = await Person(name: "Bert", dateOfBirth: game.generateDate(year: 2000), gender: Sex.male, game: game)
        let resource = dave.resources.keys.filter({$0 == sword}).first
        resource?.markForSale()
        bert.wantsToBuy(resource: sword, number: 1)
        await game.addPerson(person: bert)
        
        await game.tradeMatching(buyer: bert)

        XCTAssertEqual(resource?.matchedBuyer, bert, "Bert hasn't been matched to buy this sword")
    }

    func testExchangeRates() async throws {
        // Given buying a sword costs 5 coins
        // And John has 4 coins
        // When he tries to buy a sword
        // Then he is not able to buy one
        let sword = Resource(name: "Sword")
        sword.forSale = true
        let coin = Resource(name: "Coin")
        let exchRate = ExchangeRate(rate: 5, buyResource: sword, sellResource: coin)
        let game = GameEngine(year: 2000, month: 1)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 1980), gender: Sex.male, game: game)
        let seller = await Person(name: "Seller", dateOfBirth: game.generateDate(year: 1975), gender: Sex.female, game: game)
        seller.resources[sword] = 1
        john.resources[coin] = 4
        john.wantsToBuy(resource: sword, number: 1)
        await game.addPerson(person: john)
        await game.addPerson(person: seller)
        ConfigLoader.rates = [exchRate]

        await game.tradeMatching(buyer: john)
        await game.makeTrades(buyer: seller)

        XCTAssertFalse(john.resources.keys.contains(sword), "John managed to get a sword")

        // Given John now has 5 coins
        // When he tries to buy a sword
        // Then he is able to buy one
        // And he no longer has any coins
        john.addResource(resource: coin)

        await game.tradeMatching(buyer: john)
        await game.makeTrades(buyer: seller)

        XCTAssertTrue(john.resources.keys.contains(sword), "John didn't buy his sword")
        XCTAssertFalse(john.resources[coin] ?? 0 > 0, "John still has some coins")
    }

    func testResourceInheritance() async throws {
        // Given wheat is a non-inherited resource
        // And Daphne has wheat
        // And she also has a child
        // When Daphne dies
        // Then the child has not inherited the wheat
        let wheat = Resource(name: "Wheat")
        wheat.inheritable = false
        let game = GameEngine(year: 2000, month: 1)
        let daphne = await Person(name: "Daphne", dateOfBirth: game.generateDate(year: 2000), gender: .female, game: game)
        let child = await Person(name: "Child", dateOfBirth: game.generateDate(year: 2010), gender: .female, game: game)
        await daphne.hasChild(child: child, game: game)
        daphne.resources[wheat] = 1

        await daphne.dies(game: game)

        XCTAssertTrue(child.resources[wheat] ?? 0 == 0, "Child managed to inherit the wheat")

        // Given coin is an inherited resource
        // And Barry has coins
        // And also a child
        // When Barry dies
        // Then the child inherits the coins
        let coin = Resource(name: "Coin")
        let barry = await Person(name: "Barry", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
        await barry.hasChild(child: child, game: game)
        barry.resources[coin] = 10

        await barry.dies(game: game)

        XCTAssertTrue(child.resources[coin] ?? 0 == 10, "Child didn't inherit the coins")
    }

    func testPuttingResourcesUpForSale() async throws {
        // Given Dave is a warrior
        // And has a sword
        // And has a daughter who is a farm hand
        // And has no wife or other descendants
        // When Dave dies
        // Then his daughter inherits the sword
        // And she puts it up for sale as it is not needed for her job
        let game = GameEngine(year: 2000, month: 1)
        var warrior = Job(name: "Warrior")
        var farmhand = Job(name: "Farm Hand")
        let sword = Resource(name: "Sword")
        await game.addToSets(newJobs: [warrior, farmhand])
        let dave = await Person(name: "Dave", dateOfBirth: game.generateDate(year: 1960), gender: .male, game: game)
        dave.job = warrior
        dave.addResource(resource: sword)
        let daughter = await Person(name: "Daughter", dateOfBirth: game.generateDate(year: 1980), gender: .female, game: game)
        daughter.job = farmhand
        await dave.hasChild(child: daughter, game: game)

        await dave.dies(game: game)

        XCTAssertNotNil(daughter.resources[sword], "Daughter did not inherit the sword")
        XCTAssertGreaterThan(daughter.resources[sword] ?? 0, 0, "Daughter did not inherit the sword")
        XCTAssert(sword.forSale, "The sword is not for sale")

        // Given Alex is a chariot rider
        // And has a chariot
        // And has a son who is a warrior
        // And has no wife or other descendants
        // When Dave dies
        // Then his son inherits the chariot
        // And keeps it as he can upskill hmself
        // And becomes a chariot rider
        let experience = Skill(name: "Experience", description: "")
        warrior.learnSkills = [experience: 1]
        var chariotrider = Job(name: "Chariot Rider")
        let chariot = Resource(name: "Chariot")
        chariotrider.requiredResources = [chariot]
        chariotrider.requiredSkills = [experience]
        await game.addToSets(newJobs: [warrior, chariotrider])
        let alex = await Person(name: "Alex", dateOfBirth: game.generateDate(year: 1960), gender: .male, game: game)
        alex.job = chariotrider
        alex.addResource(resource: chariot)
        let son = await Person(name: "Son", dateOfBirth: game.generateDate(year: 1980), gender: .female, game: game)
        son.job = warrior
        son.jobStartDate = await game.generateDate(year: 1990)
        await alex.hasChild(child: son, game: game)
        await game.addPerson(person: alex)
        await game.addPerson(person: son)

        await alex.dies(game: game)
        await game.endTurn()

        XCTAssertNotNil(son.resources[chariot], "Son did not inherit the chariot")
        XCTAssertGreaterThan(son.resources[chariot] ?? 0, 0, "Son did not inherit the chariot")
        XCTAssertFalse(chariot.forSale, "The chariot is for sale")
        XCTAssertEqual(son.job, chariotrider, "Son did not become a chariot rider")

        // Given Joe is a farm hand
        // And to become a farmer requires land and Animal Husbandry skill
        // When he has the Animal Husbandry skill
        // Then land is added to his wanted resource list
        let land = Resource(name: "Land")
        let husbandry = Skill(name: "Animal Husbandry", description: "")
        var farmer = Job(name: "Farmer")
        farmer.requiredResources = [land]
        farmer.requiredSkills = [husbandry]
        farmhand.learnSkills = [husbandry: 1]
        await game.addToSets(newJobs: [farmer, farmhand])
        let joe = await Person(name: "Joe", dateOfBirth: game.generateDate(year: 1975), gender: .male, game: game)
        joe.job = farmhand
        joe.jobStartDate = await game.generateDate(year: 1990)
        await game.addPerson(person: joe)

        await game.endTurn()

        XCTAssertTrue(joe.wantedResources.keys.contains(land), "Joe does not want land to become a farmer")

        // Given the above still holds true
        // When Joe acquires land
        // Then he upskills and becomes a farmer
        // And he no longer wants land
        joe.addResource(resource: land)
        await joe.upgradeJob(resource: land, game: game)

        XCTAssertEqual(joe.job, farmer, "Joe did not become a farmer")
        XCTAssertFalse(joe.wantedResources.keys.contains(land), "Joe still wants land for some reason")
    }

    func testResourceExpiring() async throws {
        // Given being a labourer produces labour as a resource
        // And labour as a resource is only valid for one year
        // And Harry is a labourer this year
        // When the year ticks over
        // Then he has produce labour as a resource
        let game = GameEngine(year: 2000, month: 1)
        let labour = Resource(name: "Labour")
        labour.lifespan = 1
        let labourer = Job(name: "Labourer", produceResource: [labour: 1])
        let harry = await Person(name: "Harry", dateOfBirth: game.generateDate(year: 1980), gender: .male, game: game)
        harry.job = labourer

        await game.endTurn()

        XCTAssertGreaterThan(harry.resources[labour] ?? 0, 0, "Harry didn't produce the labour resource")

        // Given Harry is now no longer employed
        // And he hasn't traded his labour resource
        // When the year next ticks over
        // Then he no longer has labour in his resources
        harry.job = nil

        await game.endTurn()

        XCTAssertEqual(harry.resources[labour] ?? 0, 0, "Harry still has labour resource")

        // Given being an ironsmith produces 2 swords
        // And swords do not expire
        // And Harry is now an ironsmith
        // When the year ticks over twice
        // Then he has produced a sword
        // And it doesn't get removed
        let sword = Resource(name: "Sword")
        var ironsmith = Job(name: "Iron Smith", produceResource: [sword: 2])
        harry.job = ironsmith

        await game.endTurn()
        await game.endTurn()

        XCTAssertEqual(harry.resources[sword], 4, "Harry didn't create 2 swords or they expired")

        // Given swords now expire after 2 years
        // And Harry destroyed his current swords
        // When the year ticks over once
        // Then Harry has 2 swords
        harry.resources[sword] = nil
        sword.lifespan = 2

        await game.endTurn()

        XCTAssertEqual(harry.resources[sword], 2, "Harry didn't create 2 swords")

        // Given the above
        // When the year ticks over twice
        // Then Harry now has 4 swords (as he has created 6 but 2 expired)
        await game.endTurn()
        await game.endTurn()

        XCTAssertEqual(sword.countIgnoringAge(resources: harry.resources), 4, "Harry doesn't have 4 sword - either they're not expiring or he isn't creating them")


    }

    func testNeedingResourcesToProduce() async throws {
        // Given being an Blacksmith requires labour
        // And when you have that the Blacksmith produces a sword and a coin
        // And John is a Blacksmith who currently has 1 coin
        // And Billy is a Labourer who has 1 labour (and produces 1)
        // And the exchange rate is 1 coin for 1 labour
        // When John goes to do his job
        // Then he wants 1 Labour
        // And he trades with Billy for 1 coin
        // And he produces 1 sword
        // And Billy has 1 coin and 1 (new) labour
        let game = GameEngine(year: 100, month: 1)
        var blacksmith = Job(name: "Blacksmith")
        var labourer = Job(name: "Labourer")
        let labour = Resource(name: "Labour")
        labour.lifespan = 1
        labour.forSale = true
        let coin = Resource(name: "Coin")
        var sword = Resource(name: "Sword")
        blacksmith.produceResource[sword] = 1
        blacksmith.produceResource[coin] = 1
        sword.requiredResources[labour] = 1
        labourer.produceResource[labour] = 1
        let exchrate = ExchangeRate(rate: 1, buyResource: labour, sellResource: coin)
        let john = await Person(name: "John", dateOfBirth: game.generateDate(year: 80), gender: .male, game: game)
        let billy = await Person(name: "Billy", dateOfBirth: game.generateDate(year: 80), gender: .male, game: game)
        john.job = blacksmith
        billy.job = labourer
        john.jobStartDate = await game.generateDate(year: game.year)
        billy.jobStartDate = await game.generateDate(year: game.year)
        ConfigLoader.rates = [exchrate]
        await billy.job?.doJob(person: billy, game: game)
        await john.job?.doJob(person: john, game: game)

        await game.endTurn()

        XCTAssertGreaterThan(sword.countIgnoringAge(resources: john.resources), 0, "John did not create a sword")
        XCTAssertGreaterThan(coin.countIgnoringAge(resources: billy.resources), 0, "Billy did not get a coin from trading")
        XCTAssertGreaterThan(labour.countIgnoringAge(resources: billy.resources), 0, "Billy did not produce more labour")

        // Given to a farmer can produce 2 food and 1 coin
        // But Food requires 1 labour to create
        // And Max is a farmer
        // When the game turn ticks around
        // Then Max creates 1 food by buying 1 labour from Billy
        await john.dies(game: game)
        billy.resources[coin] = 0
        var farmer = Job(name: "Farmer")
        let food = Resource(name: "Food")
        food.requiredResources[labour] = 1
        farmer.produceResource[food] = 3
        let max = await Person(name: "Max", dateOfBirth: game.generateDate(year: 80), gender: .male, game: game)
        max.job = farmer
        max.jobStartDate = await game.generateDate(year: game.year)
        max.resources[coin] = 1
        await max.job?.doJob(person: max, game: game)

        for (res, count) in max.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in billy.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }

        await game.endTurn()

        for (res, count) in max.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in billy.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }

        XCTAssertEqual(food.countIgnoringAge(resources: max.resources), 1, "Max didn't generate exactly 1 food")
        XCTAssertEqual(coin.countIgnoringAge(resources: billy.resources), 1, "Billy didn't get coins")

        // Given Bert is also a labourer
        // And Max has inherited 2 more coins
        // When he joins the game and the turn ticks over
        // Then Max can now make 2 food
        // And Bert and Billy get the coins
        let bert = await Person(name: "Bert", dateOfBirth: game.generateDate(year: 80), gender: .male, game: game)
        bert.job = labourer
        bert.jobStartDate = await game.generateDate(year: game.year)
        max.resources[coin] = 2
        await bert.job?.doJob(person: bert, game: game)

        print(max.wantedResources.description)
        for (res, count) in max.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in billy.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in bert.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }

        await game.endTurn()

        print(max.wantedResources.description)
        for (res, count) in max.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in billy.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }
        for (res, count) in bert.resources {
            print(res.name + " " + String(count) + " " + String(res.forSale))
        }

        XCTAssertEqual(food.countIgnoringAge(resources: max.resources), 3, "Max didn't generate 2 more food")
        XCTAssertEqual(coin.countIgnoringAge(resources: billy.resources), 2, "Billy didn't get coins")
        XCTAssertEqual(coin.countIgnoringAge(resources: bert.resources), 1, "Bert didn't get coins")

    }

}

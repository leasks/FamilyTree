//
//  TreeBuilding.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 30/07/2023.
//

import XCTest
@testable import FamilyTree

final class TreeBuilding: XCTestCase {
    var game = GameEngine(year: 1970, month: 1)
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHavingFirstChild() async throws {
        //        Given John and Jane are married
        //        When they have their first son
        //        Then an extra trunk is added to the tree
        //        And it is contains the son
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = await Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                        gender: Sex.female, game: game)
        let john: Person = await Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                        gender: Sex.male, game: game)
        let son: Person = await Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                       gender: Sex.male, game: game)

        await game.setActivePerson(person: john)
        let initialDepth = await game.generation

        john.marries(spouse: jane, game: game)
        await jane.hasChild(child: son, game: game)

        let generation = await game.generation
        XCTAssertEqual(generation, initialDepth + 1,
                       "Does not have an extra trunk to tree")
        XCTAssertTrue(john.descendants.contains(son),
                       "Son is not in family tree")
    }

    func testHavingSecondChild() async throws {
        //        Given John and Jane are married
        //        And they already have at least one child
        //        When they have their next child
        //        Then an extra branch is added to the tree
        //        And it contains the next child
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = await Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                        gender: Sex.female, game: game)
        let john: Person = await Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, game: game)
        let son: Person = await Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                 gender: Sex.male, game: game)
        let child: Person = await Person(name: "Fred", dateOfBirth: formatter.date(from: "23/04/2011")!,
                                   gender: Sex.male, game: game)

        await game.setActivePerson(person: john)
        let initialDepth = await game.generation

        john.marries(spouse: jane, game: game)
        await jane.hasChild(child: son, game: game)
        
        let childBranchCount = await game.getActivePerson()?.descendants.count ?? 0
        await jane.hasChild(child: child, game: game)

        let generation = await game.generation
        XCTAssertEqual(generation, initialDepth + 1,
                       "Incorrect depth of tree")
        XCTAssertEqual(john.descendants.count, childBranchCount + 1,
                       "Incorrect number of branches on child trunk")
        XCTAssertTrue(john.descendants.contains(son),
                       "Son is not in family tree")
        XCTAssertTrue(john.descendants.contains(child),
                       "Second Child is not in family tree")
    }

    func testChildHasAChild() async throws {
        //        Given John and Jane are married
        //        And they have a son who is also married
        //        When their son has a child
        //        Then an extra trunk is added to the tree
        //        And it is marked with the child’s birthdate and name
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = await Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, game: game)
        let john: Person = await Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, game: game)
        let daughter: Person = await Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                 gender: Sex.female, game: game)
        let child: Person = await Person(name: "Fred", dateOfBirth: formatter.date(from: "23/04/2011")!,
                                   gender: Sex.male, game: game)

        await game.setActivePerson(person: john)
        let initialDepth = await game.generation

        john.marries(spouse: jane, game: game)
        await jane.hasChild(child: daughter, game: game)
        
        await daughter.hasChild(child: child, game: game)

        let generation = await game.generation
        XCTAssertEqual(generation, initialDepth + 2,
                       "Incorrect depth of tree")
        XCTAssertTrue(john.descendants.contains(where: {$0.descendants.contains(child)}),
                       "Daughter's Child is not in family tree")
    }
    
    func testGettingMarried() async throws {
        //        Given John meets Jane
        //        When they get married
        //        Then Jane is added to the tree
        //        And marked with the married date on the tree
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = await Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, game: game)
        let john: Person = await Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, game: game)

        await game.setActivePerson(person: john)

        john.marries(spouse: jane, game: game)

        XCTAssertTrue(john.spouse == jane, "Tree does not contain spouse")
        XCTAssertNotNil(john.dateOfMarriage, "Marriage date not set")
    }
    
    func testOnDeath() async throws {
        //        Given John has a family tree
        //        When he dies
        //        Then his death date is set on the tree
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let john: Person = await Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, game: game)

        await game.setActivePerson(person: john)

        await john.dies(game: game)
        
        XCTAssertNotNil(john.dateOfDeath, "Death date not set")
    }

    func testInhertingAffiliations() async throws {
        // Given Jeff's mother wants a child
        // But she hasn't married Jeff's dad yet (controversial:  TODO: Maybe represent a relationship than a marriage?)
        // When Jeff's mother tries to have a child
        // Then no child is born
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 1990)
        let birthD = calendar.date(from: components)!
        let jeffsMum = await Person(name: "Jeff's Mum", dateOfBirth: birthD, gender: Sex.female, game: game)
        await jeffsMum.hasChild(game: game)
        XCTAssertEqual(jeffsMum.descendants.count, 0, "Jeff's mum had a child but shouldn't")

        // Given Jeff's father is Celtic
        // And his mother is Celtic
        // And there are married (controversial)
        // When Jeff is born
        // Then he is Celtic
        let jeffsDad = await Person(name: "Jeff's Dad", dateOfBirth: birthD, gender: Sex.male, game: game)
        let celtic = Affiliation(name: "Celtic")
        jeffsMum.affiliations = [celtic]
        jeffsDad.affiliations = [celtic]
        jeffsMum.marries(spouse: jeffsDad, game: game)
        await jeffsMum.hasChild(game: game)
        var jeff = jeffsMum.descendants.first
        XCTAssert(jeff!.affiliations.contains(celtic), "Jeff isn't Celtic despite both parents being so")
        
        // Given Jeff's father is Roman
        // And his mother is Celtic
        // And the patriachy is in charge at the moment :(
        // When Jeff is born
        // Then he is Roman
        // But not Celtic
        let roman = Affiliation(name: "Roman")
        jeffsMum.descendants = []
        jeffsDad.descendants = []
        jeffsDad.affiliations = [roman]
        await jeffsMum.hasChild(game: game, patriachy: true)
        jeff = jeffsMum.descendants.first
        XCTAssert(jeff!.affiliations.contains(roman), "Jeff isn't Roman despite that being is father's heritage")
        XCTAssertFalse(jeff!.affiliations.contains(celtic), "Jeff is Celtic despite the patriachy")

    }
    
    func testGeneratingNewPeopleRatios() async throws {
        // Given an invasion force of Romans is 100% men
        // When the invasion happens
        // Then no women should be created
        let roman = Affiliation(name: "Roman")
        let centurion = Job(name: "Centurion")
        let npcDef = NewNPC(count: 50, minAge: 20, maxAge: 50, affiliation: roman, jobDistribution: ["Centurion":1], genderDistribution: [Sex.male: 1, Sex.female: 0])
        let invasion = Event(name: "Roman invasion", description: "An invasion of Romans", triggerYear: 100, newNPC: [npcDef])

        game = GameEngine(year: 99, month: 1)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [centurion])
        ConfigLoader.events.insert(invasion)

        await game.endTurn()

        let count = await game.persons.filter({$0.gender == Sex.female}).count
        XCTAssert(count == 0, "\(count) women were created in the invasion force")
    }

    func testTreeDepthAndWidth() async throws {
        // Given Bert is the origin of the tree
        // And Sally and Jane are his direct descendants
        // And Sally has 2 children and 1 grandchild
        // And Jane has none
        // When calculating the depth of the family tree
        // Then the answer is 4
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2000)
        let dateOfBirth = calendar.date(from: components)!
        let bert = await Person(name: "Bert", dateOfBirth: dateOfBirth, gender: Sex.male, game: game)
        let sally = await Person(name: "Sally", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        let jane = await Person(name: "Jane", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        let child1 = await Person(name: "Child1", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        let child2 = await Person(name: "Child2", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        let grandchild = await Person(name: "GrandChild", dateOfBirth: dateOfBirth, gender: Sex.female, game: game)
        bert.descendants = [sally, jane]
        sally.descendants = [child1, child2]
        child1.descendants = [grandchild]
        
        XCTAssertEqual(bert.treeDepth(), 4, "Bert's tree is not 4 deep")

        // Given the same details about Bert
        // When calculating the width of the family tree
        // Then the answer is 2
        XCTAssertEqual(bert.treeWidth(), 2, "Bert's tree is not 2 wide")

    }
}

//
//  TreeBuilding.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 30/07/2023.
//

import XCTest
@testable import FamilyTree

final class TreeBuilding: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        GameEngine.getInstance().reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHavingFirstChild() throws {
        //        Given John and Jane are married
        //        When they have their first son
        //        Then an extra trunk is added to the tree
        //        And it is contains the son
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, location: Location())
        let john: Person = Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, location: Location())
        let son: Person = Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                 gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: john)
        let initialDepth = GameEngine.getInstance().tree.keys.count

        john.marries(spouse: jane)
        jane.hasChild(child: son)

        XCTAssertEqual(GameEngine.getInstance().tree.keys.count, initialDepth + 1,
                       "Does not have an extra trunk to tree")
        XCTAssertTrue(GameEngine.getInstance().tree.contains(where: {$0.value.contains(son)}),
                       "Son is not in family tree")
    }

    func testHavingSecondChild() throws {
        //        Given John and Jane are married
        //        And they already have at least one child
        //        When they have their next child
        //        Then an extra branch is added to the tree
        //        And it contains the next child
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, location: Location())
        let john: Person = Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, location: Location())
        let son: Person = Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                 gender: Sex.male, location: Location())
        let child: Person = Person(name: "Fred", dateOfBirth: formatter.date(from: "23/04/2011")!,
                                   gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: john)
        let initialDepth = GameEngine.getInstance().tree.keys.count

        john.marries(spouse: jane)
        jane.hasChild(child: son)
        
        let childBranchCount = GameEngine.getInstance().tree[GameEngine.getInstance().generation+1]?.count ?? 0
        jane.hasChild(child: child)

        XCTAssertEqual(GameEngine.getInstance().tree.keys.count, initialDepth + 1,
                       "Incorrect depth of tree")
        XCTAssertEqual(GameEngine.getInstance().tree[GameEngine.getInstance().generation+1]?.count, childBranchCount + 1,
                       "Incorrect number of branches on child trunk")
        XCTAssertTrue(GameEngine.getInstance().tree.contains(where: {$0.value.contains(son)}),
                       "Son is not in family tree")
        XCTAssertTrue(GameEngine.getInstance().tree.contains(where: {$0.value.contains(child)}),
                       "Second Child is not in family tree")
    }

    func testChildHasAChild() throws {
        //        Given John and Jane are married
        //        And they have a son who is also married
        //        When their son has a child
        //        Then an extra trunk is added to the tree
        //        And it is marked with the child’s birthdate and name
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, location: Location())
        let john: Person = Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, location: Location())
        let daughter: Person = Person(name: "Junior", dateOfBirth: formatter.date(from: "08/06/2008")!,
                                 gender: Sex.female, location: Location())
        let child: Person = Person(name: "Fred", dateOfBirth: formatter.date(from: "23/04/2011")!,
                                   gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: john)
        let initialDepth = GameEngine.getInstance().tree.keys.count

        john.marries(spouse: jane)
        jane.hasChild(child: daughter)
        
        daughter.hasChild(child: child)

        XCTAssertEqual(GameEngine.getInstance().tree.keys.count, initialDepth + 2,
                       "Incorrect depth of tree")
        XCTAssertTrue(GameEngine.getInstance().tree.contains(where: {$0.value.contains(child)}),
                       "Daughter's Child is not in family tree")
    }
    
    func testGettingMarried() throws {
        //        Given John meets Jane
        //        When they get married
        //        Then Jane is added to the tree
        //        And marked with the married date on the tree
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let jane: Person = Person(name: "Jane", dateOfBirth: formatter.date(from: "12/03/1978")!,
                                  gender: Sex.female, location: Location())
        let john: Person = Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: john)

        john.marries(spouse: jane)

        XCTAssertTrue(GameEngine.getInstance().tree.contains(where: {$0.value.contains(jane)}), "Tree does not contain spouse")
        XCTAssertNotNil(john.dateOfMarriage, "Marriage date not set")
    }
    
    func testOnDeath() throws {
        //        Given John has a family tree
        //        When he dies
        //        Then his death date is set on the tree
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let john: Person = Person(name: "John", dateOfBirth: formatter.date(from: "09/10/1976")!,
                                  gender: Sex.male, location: Location())

        GameEngine.getInstance().setActivePerson(person: john)

        john.dies()
        
        XCTAssertNotNil(john.dateOfDeath, "Death date not set")
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

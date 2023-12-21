//
//  JobsTesting.swift
//  FamilyTreeTests
//
//  Created by Stephen Leask on 07/08/2023.
//

import XCTest
@testable import FamilyTree

final class JobsTesting: XCTestCase {
    var game = GameEngine(year: 0, month: 1)
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJobDistribution() async throws {
        // Given the Norman Conquest event introduces approximately 1000 Normans to the game
        // And the roles of Spearman, Archer and Cavalry are evenly distributed
        // And everyone to be added is over the minimum age of these jobs
        // When the event is triggered
        // Then there will be characters with Spearman, Archer and Cavalry jobs created
        // And no-one with a job of Games Developer is created
        let spearman = Job(name: "Spearman", minAge: 18)
        let archer = Job(name: "Archer", minAge: 18)
        let cavalry = Job(name: "Cavalry", minAge: 20)
        let gamesDev = Job(name: "Games Developer", minAge: 16)
        let jobsToAdd : Set<Job> = [spearman, archer, cavalry]
        let normanAffiliation = Affiliation(name: "Norman")
        let jobDist: [String: Float] = ["Spearman":0.33,"Archer":0.33,"Cavalry":0.33]
        let characterDetails = NewNPC(count: 1000, minAge: 21, maxAge: 45, affiliation: normanAffiliation, jobDistribution: jobDist)
        let normanConquest = Event(name: "Norman Conquest", description: "The Norman Conquest of England ...", triggerYear: 1066, jobsAdded: jobsToAdd, newNPC: [characterDetails])
        
        await normanConquest.apply(game: game)

        let jobs = await game.availableJobs
        let persons = await game.persons
        XCTAssert(jobs.contains(spearman), "The spearman job wasn't added")
        XCTAssertGreaterThan(persons.filter({$0.job == spearman}).count, 0, "Not enough spearmen")
        XCTAssertGreaterThan(persons.filter({$0.job == archer}).count, 0, "Not enough archers")
        XCTAssertGreaterThan(persons.filter({$0.job == cavalry}).count, 0, "Not enough cavalry")
        XCTAssertEqual(persons.filter({$0.job == gamesDev}).count, 0, "Somehow games developers were generated")
    }

    func testJobsAreGivenToRightAgesAndGenders() async throws {
        // Given the Norman Conquest event introduces approximately 1000 Normans to the game
        // And the roles of Spearman, Archer and Cavalry are evenly distributed
        // And Spearman is a role performed only by men over the age of 25
        // When the event is triggered
        // Then there will be no female spearmen
        // And no spearmen under the age of 25
        let spearman = Job(name: "Spearman", minAge: 25, allowedGenders: [Sex.male])
        let archer = Job(name: "Archer", minAge: 18)
        let cavalry = Job(name: "Cavalry", minAge: 20)
        let jobsToAdd: Set<Job> = [spearman, archer, cavalry]
        let normanAffiliation = Affiliation(name: "Norman")
        let jobDist: [String: Float] = ["Spearman":0.33,"Archer":0.33,"Cavalry":0.33]
        let characterDetails = NewNPC(count: 1000, minAge: 21, maxAge: 45, affiliation: normanAffiliation, jobDistribution: jobDist)
        let normanConquest = Event(name: "Norman Conquest", description: "The Norman Conquest of England ...", triggerYear: 1066, jobsAdded: jobsToAdd, newNPC: [characterDetails])
        
        await normanConquest.apply(game: game)
        
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 1066-25)
        let date25 = calendar.date(from: components)!
        let persons = await game.persons
        XCTAssertEqual(persons.filter({$0.job == spearman && $0.gender == Sex.female}).count, 0, "Created a female spearman")
        XCTAssertEqual(persons.filter({$0.job == spearman && $0.dateOfBirth > date25}).count, 0, "Created an underaged spearman")

    }
    
    func testReachingTheAgeToGetAJob() async throws {
        // Given Fred is 23 years old
        // And he has no job
        // And to become an Iron Smith you must be at least 25 years old
        // And this is the only available job
        // When Fred turns 24
        // Then he will remain without a job
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 1990)
        let birthD = calendar.date(from: components)!
        let fred = await Person(name: "Fred", dateOfBirth: birthD, gender: Sex.male, game: game)
        let ironSmith = Job(name: "Iron Smith", minAge: 25)

        var game = GameEngine(year: 2014, month: 1)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [ironSmith])

        await fred.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertNil(fred.job, "Fred managed to get a job as a \(fred.job?.name)")

        // Given Fred is now 24
        // And he still has no job
        // When Fred turns 25
        // Then he has become an Iron Smith
        game = GameEngine(year: 2015, month: 1)
        await fred.seekJob(startDate: game.getGameDate(), game: game)
        XCTAssertNotNil(fred.job, "Fred didn't get a job")
    }
    
    func testJobsAndAffiliations() async throws {
        // Given Jeff is a Roman
        // And a Warrior job is only for Celts
        // When he seeks a job
        // Then he does not become a Warrior
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 1990)
        let birthD = calendar.date(from: components)!
        let jeff = await Person(name: "Jeff", dateOfBirth: birthD, gender: Sex.male, game: game)
        let roman = Affiliation(name: "Roman")
        let celtic = Affiliation(name: "Celtic")
        jeff.affiliations = [roman]
        
        let warrior = Job(name: "Warrior", affiliations: [celtic])
        var game = GameEngine(year: 2020, month: 1)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [warrior])

        await jeff.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertFalse(jeff.job == warrior, "Jeff became a warrior")
    }
    
    func testJobSkills() async throws {
        // Given to become an Iron Smith you need to learn metal working skills
        // And John does not have any metal working skills
        // When he seeks a job
        // Then he does not become an Iron Smith
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 1990)
        let birthD = calendar.date(from: components)!
        let metalWorking = Skill(name: "Metal Working", description: "")
        let ironSmith = Job(name: "Iron Smith", requiredSkills: [metalWorking])
        let john = await Person(name: "John", dateOfBirth: birthD, gender: Sex.male, game: game)

        var game = GameEngine(year: 2010, month: 1)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [ironSmith])
        await game.addPerson(person: john)
        await john.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertFalse(john.job == ironSmith, "John managed to get a job as an Iron Smith")
        
        // Given John is an Iron Smith Apprentice
        // And working 5 years as Iron Smith Apprentice equips you with metal working skills
        // When John has been an Iron Smith for 3 years
        // Then he still does not have metal working skills
        components = DateComponents(year: 2010)
        let startD = calendar.date(from: components)
        let ironSmithApprentice = Job(name: "Iron Smith Apprentice", learnSkills: [metalWorking:5])
        john.job = ironSmithApprentice
        john.jobStartDate = startD
        
        await game.endTurn()
        await game.endTurn()
        await game.endTurn()

        XCTAssertFalse(john.skills?.contains(metalWorking) ?? true, "John somehow learnt metal working")
        
        // Given John is an Iron Smith Apprentice
        // And working 5 years as Iron Smith Apprentice equips you with metal working skills
        // When John has been an Iron Smith for 5 years
        // Then he now has metal working skills
        await game.endTurn()
        await game.endTurn()

        XCTAssertTrue(john.skills?.contains(metalWorking) ?? false, "John didn't learn metal working")

        // Given to become an Iron Smith you need to learn metal working skills
        // And working 5 years as Iron Smith Apprentice equips you with metal working skills
        // And John is working as an Iron Smith Apprentice
        // And he has been doing that job for 5 years
        // When he seeks a job
        // Then he does become an Iron Smith
//        john.seekJob()
        
        XCTAssertTrue(john.job == ironSmith, "John couldn't get a job as an Iron Smith")
    }

    func testJobTypeClassifications() throws {
        // TODO: Given Legionary, Centurion and Legate are all miltary jobs
        // When < something happens >
        // Then the jobs all have the same type?
        
        // TODO: Given John has pursued a military career
        // When his son starts to look for work
        // Then he will start a military career too (but not always) ??
    }
    
    func testJobAffiliations() async throws {
        // Given Harry is Celtic
        // And the job of Auxilia is reserved for non-Romans
        // But gives the affiliation of Roman
        // When Harry becomes an Auxilia
        // Then he is additionally affiliated with Roman
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2000)
        let dateOfBirth = calendar.date(from: components)!
        let celtic = Affiliation(name: "Celtic")
        let roman = Affiliation(name: "Roman")
        let harry = await Person(name: "Harry", dateOfBirth: dateOfBirth, gender: Sex.male, game: game)
        harry.affiliations = [celtic]
        let auxilia = Job(name: "Auxilia", blockedAffiliations: [roman], earnAffiliations: [roman])

        var game = GameEngine(year: 2020, month: 1)
        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [auxilia])
        await game.addPerson(person: harry)

        await harry.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertEqual(harry.job, auxilia, "Harry didn't become an Auxilia")
        XCTAssertTrue(harry.affiliations.contains(roman), "Harry didn't gain the Roman affiliation")
        
        // Given John is Roman
        // When he looks for a job
        // Then he cannot become an Auxilia
        let john = await Person(name: "John", dateOfBirth: dateOfBirth, gender: Sex.male, game: game)
        john.affiliations = [roman]

        await game.addPerson(person: john)
        await john.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertNotEqual(john.job, auxilia, "John managed to become an Auxilia despite being Roman")
        
        // Given Harry is Celtic
        // And he is an Auxilia so has gained Roman affiliation
        // And Legionary is a job for pure Romans only
        // When Harry tries to become a Legionary
        // Then he is rejected and has to remain an Auxilia
        let legionary = Job(name: "Legionary", affiliations: [roman], blockedAffiliations: [celtic])

        await game.addToSets(newInjuries: [], newAffiliations: [], newJobs: [legionary])
        await harry.seekJob(startDate: game.getGameDate(), game: game)
        
        XCTAssertNotEqual(harry.job, legionary, "Harry became a Legionary even though he isn't pure Roman")
    }

    func testJobLimits() async {
        // Given there can be only one tribal leader
        // And it is the only job defined
        // And someone already has the job
        // When a character tries to find a job
        // Then they do not get the job
        var leader = Job(name: "Tribal Leader")
        leader.maxCount = 1
        let game = GameEngine(year: 2020, month: 1)
        await game.addToSets(newJobs: [leader])
        let birthD = await game.generateDate(year: 2000)
        let person = await Person(name: "Person", dateOfBirth: birthD, gender: .male, game: game)
        let person2 = await Person(name: "Person", dateOfBirth: birthD, gender: .male, game: game)
        let afil = Affiliation(name: "The Tribe")
        person.affiliations = [afil]
        person2.affiliations = [afil]
        person.job = leader
        await game.addPerson(person: person)
        await game.addPerson(person: person2)

        await person2.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertFalse(person2.job == leader, "Somehow we have 2 tribal leaders")

        // Given a new affiliation is added to the game
        // And there is a new person with that affiliation
        // When they try to find a job
        // Then they can become the tribal leader
        let person3 = await Person(name: "Person", dateOfBirth: birthD, gender: .male, game: game)
        let newAfil = Affiliation(name: "New Afil")
        person3.affiliations = [newAfil]
        await game.addPerson(person: person3)

        await person3.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertTrue(person3.job == leader, "They didn't get the leaders job despite being a new tribe")

        // Given the original tribe's leader dies
        // When the second person in that tribe tries to find a job
        // Then they become the tribal leader
        await person.dies(game: game)

        await person2.seekJob(startDate: game.getGameDate(), game: game)

        XCTAssertTrue(person2.job == leader, "The original person didn't get the leaders job despite the death")

    }

    func testFamilyJobInheritance() async {
        // Given Bert is a tribal leader
        // And he has a son, George
        // When Bert dies
        // Then George becomes tribal leader
        let game = GameEngine(year: 2020, month: 1)
        var leader = Job(name: "Tribal Leader")
        leader.type = .military
        var blacksmith = Job(name: "Blacksmith")
        blacksmith.type = .trade
        let rate = FlatRates(rate: 1, type: "Inherit Job")
        ConfigLoader.rates = [rate]
        let bert = await Person(name: "Bert", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
        let george = await Person(name: "George", dateOfBirth: game.generateDate(year: 2010), gender: .male, game: game)
        let harry = await Person(name: "Harry", dateOfBirth: game.generateDate(year: 2009), gender: .male, game: game)
        harry.familyBusiness = .military
        bert.job = leader
        await bert.hasChild(child: george, game: game)
        await game.addPerson(person: bert)
        await game.addPerson(person: harry)
        await game.addPerson(person: george)
        await game.addToSets(newJobs: [leader, blacksmith])

        await bert.dies(game: game)

        for person in await game.persons {
            await person.seekJob(startDate: game.getGameDate(), game: game)
        }

        XCTAssertTrue(george.job == leader, "George did not become the leader")

        // Given George is the tribal leader
        // But he has no descendants
        // When he dies
        // Then the tribal leader is someone else from the tribe
        await george.dies(game: game)

        for person in await game.persons {
            await person.seekJob(startDate: game.getGameDate(), game: game)
        }

        XCTAssertTrue(harry.job == leader, "Harry did not become the leader, although this might be ok")

        // Given Arnie is a Blacksmith
        // And he has a son, Fred
        // And it is 100% likely that children will follow their parent's footsteps
        // When Fred looks for a job
        // Then he will become a blacksmith apprentice
        let arnie = await Person(name: "Arnie", dateOfBirth: game.generateDate(year: 2000), gender: .male, game: game)
        let fred = await Person(name: "Fred", dateOfBirth: game.generateDate(year: 2010), gender: .male, game: game)
        arnie.job = blacksmith
        await arnie.hasChild(child: fred, game: game)
        await game.addPerson(person: arnie)
        await game.addPerson(person: fred)

        await arnie.dies(game: game)

        for person in await game.persons {
            await person.seekJob(startDate: game.getGameDate(), game: game)
        }

        XCTAssertTrue(fred.job?.type == blacksmith.type, "Fred didn't follow in Arnie's footsteps")

    }
}

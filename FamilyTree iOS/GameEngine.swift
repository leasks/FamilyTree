//
//  GameEngine.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

class GameEngine {
    var year: Int
    var month: Int
    var generation: Int = 0
    var availableInjuries: Set<Injury> = []
    var availableAffiliations: Set<Affiliation> = []
    var appliedEvents: Set<Event> = []
    var running: Bool = true
    var tree: [Int: Set<Person>] = [:]
    var activePerson: Person?
    var rates: Set<Rates> = []
    var names: Set<Name> = []
    var events: Set<Event> = []
    var persons: Set<Person> = []
    static var theGame: GameEngine?
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    func setActivePerson(person: Person) {
        generation += 1
        activePerson = person
        
        if !tree.contains(where: {$0.value.contains(person)}) {
            let newPerson: Set<Person> = [person]
            GameEngine.getInstance().tree[generation] = newPerson
        }
    }
    
    func getActivePerson() -> Person {
        return activePerson!
    }
    
    func active() -> Bool {
        return running
    }
    
    func endGame() {
        self.running = false
    }
    
    func reset() {
        GameEngine.theGame = nil
    }
    
    static func getInstance() -> GameEngine {
        if GameEngine.theGame == nil {
            // TODO: Need to read the start date and year from configuration
            GameEngine.theGame = GameEngine(year: 0, month: 12)
            GameEngine.theGame!.loadRates()
            GameEngine.theGame!.loadNames()
            GameEngine.theGame!.loadEvents()
            
            // TODO: Possibly move this to a start game function or is this the start game function?
            GameEngine.theGame!.createNPCs()
        }
        
        return GameEngine.theGame!
    }
    
    
    // TODO: Move the loaders in to a config loader class/struct
    func loadRates() {
        guard let path = Bundle.main.path(forResource: "AgeBasedRates", ofType: "json") else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([AgeBasedRates].self, from: data)
            self.rates.formUnion(result)
        } catch {
            print(error)
        }

        guard let path = Bundle.main.path(forResource: "FlatRates", ofType: "json") else { return }
                
        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([FlatRates].self, from: data)
            self.rates.formUnion(result)
        } catch {
            print(error)
        }

    }
    
    func loadNames() {
        guard let path = Bundle.main.path(forResource: "Names", ofType: "json") else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Name].self, from: data)
            self.names.formUnion(result)
        } catch {
            print(error)
        }
        
    }
 
    func loadEvents() {
        guard let path = Bundle.main.path(forResource: "Events", ofType: "json") else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Event].self, from: data)
            self.events.formUnion(result)
        } catch {
            print(error)
        }
        
    }
    
    func endTurn() {
        // End the game turn and advance the clock
        GameEngine.getInstance().year += 1

        // Add any newly triggered events
        let gameD = GameEngine.getInstance().year

        for event in events.filter({$0.triggerYear == gameD && !appliedEvents.contains($0)}) {
            print(event.description)
            event.apply()
            appliedEvents.insert(event)
        }
        
        // Apply any NPC rules based on rates, but only to alive NPCs
        for character in persons.filter({$0.dateOfDeath == nil}) {
            for rate in rates {
                rate.apply(person: character)
            }
            
            for injury in availableInjuries {
                injury.apply(person: character)
            }
        }
    }
        
    func createNPCs() {
        let people = Int.random(in: 80...120)
        let calendar = Calendar(identifier: .gregorian)

        for _ in (1...people) {
            let components = DateComponents(year: GameEngine.getInstance().year - Int.random(in: 1...40), month: Int.random(in: 1...12), day: Int.random(in: 1...28))
            var person: Person = Person(name: "Temp", dateOfBirth: calendar.date(from: components)!, gender: Sex.female)
            person = person.generateRandomPerson()
            person.dateOfBirth = calendar.date(from: components)!

            persons.insert(person)
        }
    }
    
    func getGameDate() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: GameEngine.getInstance().year, month: GameEngine.getInstance().month)
        return calendar.date(from: components)!
    }
    
    func getMaxDate() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2999, month: 12)
        return calendar.date(from: components)!
    }
    
    func getMinDate() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: -4000, month: 1)
        return calendar.date(from: components)!
    }

}

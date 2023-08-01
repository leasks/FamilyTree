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
    var running: Bool = true
    var tree: [Int: Set<Person>] = [:]
    var activePerson: Person?
    var rates: Set<Rates> = []
    var names: Set<Name> = []
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
            GameEngine.theGame = GameEngine(year: 0, month: 1)
            GameEngine.theGame!.loadRates()
            GameEngine.theGame!.loadNames()
        }
        
        return GameEngine.theGame!
    }
    
    func loadRates() {
        guard let path = Bundle.main.path(forResource: "FertilityRates", ofType: "json") else { return }
 
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

}

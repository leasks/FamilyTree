//
//  Injury.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Injury: Codable {
    let id: UUID
    var name: String
    var description: String?
    var cureID: UUID?

    var impactedJobs: Set<JobType>?
    var locationIDs: Set<UUID>?

    var likelihood: Float?
    var untreatedMortalityID: UUID?
    var treatedMortalityID: UUID?
    
    // Computed properties for backward compatibility
    var cure: Cure? {
        get {
            guard let id = cureID else { return nil }
            // Cure is a simple struct, so we need to handle it differently
            // For now, return nil as Cure isn't stored in ConfigLoader
            return nil
        }
        set {
            cureID = newValue?.id
        }
    }
    
    var location: Set<Location>? {
        get {
            guard let ids = locationIDs else { return nil }
            return Set(ids.compactMap { ConfigLoader.findLocation(byID: $0) })
        }
        set {
            locationIDs = newValue != nil ? Set(newValue!.map { $0.id }) : nil
        }
    }
    
    var untreatedMortality: AgeBasedRates? {
        get {
            guard let id = untreatedMortalityID else { return nil }
            return ConfigLoader.findRate(byID: id) as? AgeBasedRates
        }
        set {
            untreatedMortalityID = newValue?.id
        }
    }
    
    var treatedMortality: AgeBasedRates? {
        get {
            guard let id = treatedMortalityID else { return nil }
            return ConfigLoader.findRate(byID: id) as? AgeBasedRates
        }
        set {
            treatedMortalityID = newValue?.id
        }
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, cureID: UUID? = nil, 
         impactedJobs: Set<JobType>? = nil, locationIDs: Set<UUID>? = nil, 
         likelihood: Float? = nil, untreatedMortalityID: UUID? = nil, 
         treatedMortalityID: UUID? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.cureID = cureID
        self.impactedJobs = impactedJobs
        self.locationIDs = locationIDs
        self.likelihood = likelihood
        self.untreatedMortalityID = untreatedMortalityID
        self.treatedMortalityID = treatedMortalityID
    }
    
    func apply(person: Person, game: GameEngine, isPlayer: Bool = false) async {
        // TODO: Add treatment check and potential removal of injury when treated
        // If this injury only affects certain jobs then check and return if
        // the person does not have this job

        if let impactedJobs = impactedJobs, let job = person.job {
            if !impactedJobs.contains(job.type ?? .general) { return }
        } else if impactedJobs != nil {
            return
        }
        
        // If this injury is only happening in certain locations then check and
        // return if the person is not in that location
        if let location = self.location, let personLocation = person.location {
            if !location.contains(personLocation) && location.count > 0 { return }
        }
        
        if !person.injuries.contains(self) && Float.random(in: 0...1) < self.likelihood ?? 0 {
            // The injury happened so add to list but only if don't already have it
            person.injuries.insert(self)
            Task {
                if isPlayer {
                    await person.addInjuryEvent(injury: self, game: game)
                }
            }
        }
        
        if person.injuries.contains(self) {
            // Now check the mortality rates on the injury to see if this is fatal
            Task {
                await self.untreatedMortality?.apply(person: person, game: game)
            }
            if person.dateOfDeath != nil {
                person.causeOfDeath = self.name

                // TODO: How can I check if this person is related to the player - perhaps attribute of player on the person and traverse and keep parents
                if let spouse = person.spouse, spouse.isThePlayer {
                    await spouse.addFamilyDeathEvent(person: person, game: game)
                }
                //                Task {
//                // Add a player event if they have a spouse
//                    let player = GameEngine.getActivePerson()
//                    if player.spouse == person {
//                        Task {
//                            await player.addFamilyDeathEvent(person: person)
//                        }
//                        person.spouse!.spouse = nil
//                    }
//
//                    if player.descendants.contains(person) ?? false {
//                        player.addFamilyDeathEvent(person: person)
//                    }
//                }

            }
        }
    }

}
extension Injury: Hashable {
    static func == (lhs: Injury, rhs: Injury) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

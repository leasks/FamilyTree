//
//  Injury.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Injury: Codable {
    var name: String
    var description: String?
    var cure: Cure?

    var impactedJobs: Set<JobType>?
    var location: Set<Location>?

    var likelihood: Float?
    var untreatedMortality: AgeBasedRates?
    var treatedMortality: AgeBasedRates?
    
    func apply(person: Person, game: GameEngine, isPlayer: Bool = false) async {
        // TODO: Add treatment check and potential removal of injury when treated
        // If this injury only affects certain jobs then check and return if
        // the person does not have this job

        if impactedJobs != nil  && person.job != nil {
            if !impactedJobs!.contains(person.job!.type ?? .general) { return }
        } else if impactedJobs != nil {
            return
        }
        
        // If this injury is only happening in certain locations then check and
        // return if the person is not in that location
        if self.location != nil && person.location != nil {
            if !self.location!.contains(person.location!) && self.location!.count > 0 { return }
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
                if person.spouse?.isThePlayer ?? false {
                    await person.spouse!.addFamilyDeathEvent(person: person, game: game)
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
        return lhs.name == rhs.name 
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

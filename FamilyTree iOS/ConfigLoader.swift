//
//  ConfigLoader.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 04/09/2023.
//

import Foundation

struct EventConfig: Codable {
    var configFile: String
    var order: Int
}

class ConfigLoader {
    static let dateFormatter = DateFormatter()
    static let decoder = JSONDecoder()
    static var rates: Set<Rates> = []
    static var names: Set<Name> = []
    static var affiliations: Set<Affiliation> = []
    static var jobs: Set<Job> = []
    static var locations: Set<Location> = []
    static var events: Set<Event> = []
    static var injuries: Set<Injury> = []
    static var socialClasses: Set<SocialClass> = []
    static var resources: Set<Resource> = []
    static var gameStartYear: Int = 0
    static var startAffiliations: Set<Affiliation> = []

    static func load() {
        rates = []
        names = []
        affiliations = []
        socialClasses = []
        resources = []
        jobs = []
        locations = []
        events = []
        injuries = []
            
        loadLocations()
        loadAffiliations()
        loadLocationsFounded()
        loadSocialClasses()
        loadResources()
        loadResources()  // Load twice so can sweep up requirements
        loadRates()
        loadJobs()
        loadNames()
        loadInjuries()
        loadEvents()
    }

    static func loadRates() {
        guard let path = Bundle.main.path(forResource: "AgeBasedRates", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([AgeBasedRates].self, from: data)
            self.rates.formUnion(result)
        } catch {
            print("Issue loading rates")
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

        guard let path = Bundle.main.path(forResource: "ExchRates", ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([ExchangeRate].self, from: data)
            self.rates.formUnion(result)
        } catch {
            print(error)
        }

    }

    static func loadNames() {
        guard let path = Bundle.main.path(forResource: "Names", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Name].self, from: data)
            self.names.formUnion(result)
        } catch {
            print("Issue loading names")
            print(error)
        }

    }

    static func loadAffiliations() {
        guard let path = Bundle.main.path(forResource: "Affiliations", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Affiliation].self, from: data)
            self.affiliations.formUnion(result)
        } catch {
            print("Issue loading affiliations")
            print(error)
        }

    }

    static func loadSocialClasses() {
        guard let path = Bundle.main.path(forResource: "SocialClass", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([SocialClass].self, from: data)
            self.socialClasses.formUnion(result)
        } catch {
            print("Issue loading Social Classes")
            print(error)
        }

    }

    static func loadResources() {
        guard let path = Bundle.main.path(forResource: "Resources", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Resource].self, from: data)
            for res in result {
                self.resources.mergeInsert(res)
            }
        } catch {
            print("Issue loading Resources")
            print(error)
        }

    }

    static func loadJobs() {
        guard let path = Bundle.main.path(forResource: "Jobs", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Job].self, from: data)
            self.jobs.formUnion(result)
        } catch {
            print("Issue loading jobs")
            print(error)
        }

    }

    static func loadLocations() {
        guard var path = Bundle.main.path(forResource: "Locations-Region", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Region].self, from: data)
            self.locations.formUnion(result)
        } catch {
            print("Issue loading regions")
            print(error)
        }

        guard var path = Bundle.main.path(forResource: "Locations-County", ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([County].self, from: data)
            for res in result {
                self.locations.insert(res)
            }
        } catch {
            print("Issue loading counties")
            print(error)
        }

        guard var path = Bundle.main.path(forResource: "Locations-Town", ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Town].self, from: data)
            self.locations.formUnion(result)
        } catch {
            print("Issue loading towns")
            print(error)
        }

    }

    static func loadLocationsFounded() {
        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        guard var path = Bundle.main.path(forResource: "Locations-Town", ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Town].self, from: data)
            for town in result {
                self.locations.mergeInsert(town)
            }
        } catch {
            print("Issue setting the foundedby on towns")
            print(error)
        }

    }

    static func loadEvents() {
        guard let path = Bundle.main.path(forResource: "Events", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([EventConfig].self, from: data)

            for config in result.sorted(by: {$0.order < $1.order}) {
                do {
                    let path1 = Bundle.main.path(forResource: config.configFile, ofType: "json")
                    let data1 = try Data(contentsOf: URL(filePath: path1!))
                    let result1 = try decoder.decode([Event].self, from: data1)
                    self.events.formUnion(result1)

                    if config.configFile == "GameStart" {
                        // This is a special config file which should only have 1 event
                        // and the trigger year sets the game start year
                        gameStartYear = result1.first?.triggerYear ?? 0
                        startAffiliations = result1.first?.affiliationsAdded ?? []
                    }
                } catch {
                    print("Issue loading events in " + config.configFile)
                    print(error)
                }
            }

        } catch {
            print("Issue loading event config")
            print(error)
        }

    }

    static func loadInjuries() {
        guard let path = Bundle.main.path(forResource: "Injuries", ofType: "json") else { return }

        dateFormatter.dateFormat = "dd/MM/yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            let result = try decoder.decode([Injury].self, from: data)
            self.injuries.formUnion(result)
        } catch {
            print("Issue loading injuries")
            print(error)
        }

    }

}

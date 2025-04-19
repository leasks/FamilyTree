//
//  NPC.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 19/04/2025.
//

import Foundation

struct NewNPC: Codable {
    private enum CodingKeys: String, CodingKey {
        case count
        case minAge
        case maxAge
        case affiliation
        case jobDistribution
        case genderDistribution
    }

    // Sub structure representing the job distribution
    // job = the job name, this can then be used to look-up from the Job dictionary on the game engine
    // distributionType = the type of distribution of the job, either count or percentage
    // distribution = the distribution of the job, either a count or percentage
    struct JobDistribution: Codable {
        // Enum of the distribution types
        enum DistributionType: String, Codable {
            case count
            case percentage
        }

        let job: String
        let distributionType: DistributionType
        let distribution: Float
    }

    let count: Int
    let minAge: Int
    let maxAge: Int
    let affiliation: Affiliation?
    let jobDistribution: [JobDistribution]
    var genderDistribution: [Sex: Float]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decode(Int.self, forKey: .count)
        self.minAge = try container.decode(Int.self, forKey: .minAge)
        self.maxAge = try container.decode(Int.self, forKey: .maxAge)
        self.jobDistribution = try container.decode([JobDistribution].self, forKey: .jobDistribution)
        self.genderDistribution = try container.decodeIfPresent([Sex: Float].self, forKey: .genderDistribution)

        // Look up the affilliations through its name from the ConfigLoader
        var strAffil = try container.decodeIfPresent(String.self, forKey: .affiliation)
        self.affiliation = ConfigLoader.affiliations.first(where: {$0.name == strAffil})!
    }

    init (count: Int, minAge: Int, maxAge: Int, affiliation: Affiliation? = nil, jobDistribution: [JobDistribution]? = [], genderDistribution: [Sex: Float]? = [:]) {
        self.count = count
        self.minAge = minAge
        self.maxAge = maxAge
        self.genderDistribution = genderDistribution
        self.jobDistribution = jobDistribution ?? []
        self.affiliation = affiliation
    }
}


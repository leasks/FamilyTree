//
//  Affiliation.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Affiliation {
    var name: String
    var likedAffiliations: Set<Affiliation>
    var dislikedAffiliations: Set<Affiliation>
    var startDate: Date
    var endDate: Date
}

extension Affiliation: Hashable {
    static func == (lhs: Affiliation, rhs: Affiliation) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

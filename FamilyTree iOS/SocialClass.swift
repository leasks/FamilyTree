//
//  SocialClass.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 11/10/2023.
//

import Foundation

struct SocialClass: Codable {
    var name: String
    var startDate: Date
    var endDate: Date
    var affiliations: Set<Affiliation>?
    var wealth: Float = -1
}
extension SocialClass: Hashable {
    static func == (lhs: SocialClass, rhs: SocialClass) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

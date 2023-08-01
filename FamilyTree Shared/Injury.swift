//
//  Injury.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Injury {
    var name : String
    
    var minLengthWeeks : Int
    
    var maxLengthWeeks : Int
    
    var cure : Cure
    
    var likelihood : Float
}

extension Injury: Hashable {
    static func == (lhs: Injury, rhs: Injury) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

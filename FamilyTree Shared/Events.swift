//
//  Events.swift
//  FamilyTree
//
//  Created by Stephen Leask on 30/07/2023.
//

import Foundation

struct Events {
    var name : String
    
    var description : String
    
    var startDate : Date
    
    var injuriesAdded : Set<Injury>
    
    var injuriesRemoved : Set<Injury>
    
    var affiliationsAdded : Set<Affiliation>
    
    var affiliationsRemoved : Set<Affiliation>
}

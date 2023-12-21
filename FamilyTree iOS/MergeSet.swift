//
//  MergeSet.swift
//  FamilyTree iOS
//
//  Created by Stephen Leask on 28/08/2023.
//

import Foundation

extension Set {
    mutating func mergeInsert(_ newMember: Element) -> Bool {
        if self.contains(newMember) {
            var newInsert: Element? = newMember
            switch newMember {
            case is Affiliation:
                let curVal = self.remove(newMember) as? Affiliation
                var newVal = newMember as? Affiliation
                if newVal?.capital == nil { newVal?.capital = curVal?.capital }
                if newVal?.dislikedAffiliations == nil { newVal?.dislikedAffiliations = curVal?.dislikedAffiliations }
                if newVal?.likedAffiliations == nil { newVal?.likedAffiliations = curVal?.likedAffiliations }
                if newVal?.startDate == nil { newVal?.startDate = curVal?.startDate }
                if newVal?.endDate == nil { newVal?.endDate = curVal?.endDate }
                if newVal?.capital == nil { newVal?.capital = curVal?.capital }
                newInsert = newVal as? Element

            case is Injury:
                let curVal = self.remove(newMember) as? Injury
                var newVal = newMember as? Injury
                if newVal?.location == nil {
                    newVal?.location = curVal?.location
                } else {
                    newVal?.location?.formUnion(curVal?.location ?? [])
                }
                newInsert = newVal as? Element

            case is Town:
                let curVal = self.remove(newMember) as? Town
                newInsert = newMember

            case is Resource:
                let curVal = self.remove(newMember) as? Resource
                newInsert = newMember

            default:
                break
            }
            return self.insert(newInsert!).inserted

        }
        return self.insert(newMember).inserted
    }

    mutating func removeAttributes(_ member: Element) -> Element? {
        if self.contains(member) {
            var newInsert: Element? = member
            switch member {
            case is Injury:
                var curVal = self.remove(member) as? Injury
                let oldVal = member as? Injury
                if oldVal?.location != nil {
                    let newloc = curVal?.location?.subtracting(oldVal!.location!)
                    curVal?.location = newloc
                }
                if curVal?.location?.count == 0 {
                    return member
                }
                newInsert = curVal as? Element

            default:
                break
            }
            self.insert(newInsert!)
            return member

        }
        return self.remove(member)
    }
}

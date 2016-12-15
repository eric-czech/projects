//
//  Group.swift
//  Wakey2
//
//  Created by Eric Czech on 12/14/16.
//  Copyright © 2016 Eric Czech. All rights reserved.
//

import Foundation

public struct Group: Equatable, CustomStringConvertible {
    public let id: String
    public let name: String
    
    public func toSelector() -> LightTargetSelector {
        return LightTargetSelector(type: .GroupID, value: id)
    }
    
    // MARK: Printable
    public var description: String {
        return "<Group id: \"\(id)\", label: \"\(name)\">"
    }
}

public func ==(lhs: Group, rhs: Group) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

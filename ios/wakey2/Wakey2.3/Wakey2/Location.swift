//
//  Location.swift
//  Wakey2
//
//  Created by Eric Czech on 12/14/16.
//  Copyright © 2016 Eric Czech. All rights reserved.
//

import Foundation

public struct Location: Equatable {
    public let id: String
    public let name: String
    
    public func toSelector() -> LightTargetSelector {
        return LightTargetSelector(type: .LocationID, value: id)
    }
    
    // MARK: Printable
    public var description: String {
        return "<Location id: \"\(id)\", label: \"\(name)\">"
    }
}

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

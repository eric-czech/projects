//
//  Error.swift
//  Wakey2
//
//  Created by Eric Czech on 12/14/16.
//  Copyright © 2016 Eric Czech. All rights reserved.
//

import Foundation


public let ErrorDomain: String = "LIFXHTTPKitErrorDomain"

public enum ErrorCode: Int {
    // LIFXHTTPKit Errors
    case JSONInvalid
    case UnacceptableSelector
    
    // HTTP Errors
    case UnexpectedHTTPStatusCode
    case Unauthorized // 401
    case Forbidden // 403
    case TooManyRequests // 429
    case ServerError // 5XX
}

struct Error {
    let code: ErrorCode
    let message: String
    
    init(code: ErrorCode, message: String) {
        self.code = code
        self.message = message
    }
    
    func toNSError() -> NSError {
        return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

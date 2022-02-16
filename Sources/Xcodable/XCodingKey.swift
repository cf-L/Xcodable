//
//  XcodingKey.swift
//  
//
//  Created by lcf on 2022/2/12.
//

import Foundation

struct XcodingKey {
    let stringValue: String
    let intValue: Int?
    
    init<S: LosslessStringConvertible>(_ stringValue: S) {
        self.stringValue = (stringValue as? String) ?? String(stringValue)
        self.intValue = nil
    }
}

extension XcodingKey: CodingKey {

    init?(stringValue: String) {
        self.init(stringValue)
    }
    
    init?(intValue: Int) {
        self.init(intValue)
    }
}

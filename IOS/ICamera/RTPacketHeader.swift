//
//  RTPacketHeader.swift
//  ICamera
//
//  Created by Johan den Boer on 21/04/2020.
//  Copyright © 2020 Johan den Boer. All rights reserved.
//

import Foundation

struct RTPacketHeader {
    let size: String
    
    init(size: String) {
        self.size = size
    }
    
    func serialize() -> Data {
        var result = Data()
        result.append(size.data(using: .utf8)!)
        return result
    }
}

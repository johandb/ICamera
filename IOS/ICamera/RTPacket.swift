//
//  RTPacket.swift
//  ICamera
//
//  Created by Johan den Boer on 19/04/2020.
//  Copyright © 2020 Johan den Boer. All rights reserved.
//

import Foundation

struct RTPacket {
    let size: String
    let data: Data
    
    init(size: String, data: Data) {
        self.data = data
        self.size = size
    }
    
    func serialize() -> Data {
        var result = Data()
        result.append(size.data(using: .utf8)!)
        result.append(data)
        return result
    }
}

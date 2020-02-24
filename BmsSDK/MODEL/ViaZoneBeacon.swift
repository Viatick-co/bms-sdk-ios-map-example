//
//  ViaMinisite.swift
//  BLE MS SDK
//
//  Created by Bie Yaqing on 25/4/18.
//  Copyright © 2018 Bie Yaqing. All rights reserved.
//

import Foundation

public struct ViaZoneBeacon {
    var deviceId: Int;
    var uuid: String;
    var major: Int;
    var minor: Int;
    
    init(deviceId: Int, uuid: String, major: Int, minor: Int) {
        self.deviceId = deviceId;
        self.uuid = uuid;
        self.major = major;
        self.minor = minor;
    }
    
    func same(zone: ViaZoneBeacon) -> Bool {
        return self.deviceId == zone.deviceId;
    }
}

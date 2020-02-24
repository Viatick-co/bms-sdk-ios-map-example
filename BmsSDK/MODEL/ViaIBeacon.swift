//
//  ViaIBeacon.swift
//  BLE MS SDK
//
//  Created by Bie Yaqing on 9/3/18.
//  Copyright © 2018 Bie Yaqing. All rights reserved.
//

import Foundation
import CoreLocation

internal struct ViaIBeacon {
    var iBeacon: CLBeacon
    var maxDistance: Double
    var isRequested: Bool
    var disappearIdx: Int
    var description: String {
        get {
            return self.iBeacon.description + " " + String(maxDistance) + " " + String(isRequested) + " " + String(disappearIdx)
        }
    }
    func same(viaIBeacon: ViaIBeacon) -> Bool {
        if self.iBeacon.proximityUUID.uuidString == viaIBeacon.iBeacon.proximityUUID.uuidString && self.iBeacon.major == viaIBeacon.iBeacon.major && self.iBeacon.minor == viaIBeacon.iBeacon.minor {
            return true
        } else {
            return false
        }
    }
}

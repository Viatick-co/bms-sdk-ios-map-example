//
//  ViaMinisite.swift
//  BLE MS SDK
//
//  Created by Bie Yaqing on 25/4/18.
//  Copyright © 2018 Bie Yaqing. All rights reserved.
//

import Foundation

public struct ViaZone {
    var zoneId: Int;
    var name: String?;
    var remark: String?;
    var image: String?;
    var beacons: [ViaZoneBeacon];
    
    init(zoneId: Int, name: String?, remark: String?, image: String?, beacons: [ViaZoneBeacon]) {
        self.zoneId = zoneId;
        self.name = name;
        self.remark = remark;
        self.image = image;
        self.beacons = beacons;
    }
    
    func same(zone: ViaZone) -> Bool {
        return self.zoneId == zone.zoneId;
    }
}

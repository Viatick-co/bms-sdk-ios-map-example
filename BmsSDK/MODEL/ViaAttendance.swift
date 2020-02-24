//
//  ViaAttendance.swift
//  TestSDK
//
//  Created by Viatick on 16/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation

internal struct ViaAttendance {
    var attendanceId: Int;
    var firstAttendance: UInt64;
    var attendanceTime: UInt64;
    var status : AttendanceStatus;
    
    init() {
        self.attendanceId = 0;
        self.firstAttendance = 0;
        self.attendanceTime = 0;
        self.status = AttendanceStatus.CHECKOUT;
    }
}

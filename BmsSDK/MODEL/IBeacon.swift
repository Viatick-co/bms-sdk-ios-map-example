//
//  IBeacon.swift
//  TestSDK
//
//  Created by Viatick on 24/10/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation

public struct IBeacon {
    public var uuid:String;
    public var major:Int;
    public var minor:Int;
    public var distance:Double;
    
    public init(uuid: String, major: Int, minor: Int) {
        self.uuid = uuid;
        self.major = major;
        self.minor = minor;
        self.distance = 0;
    }
    
    public func getKey() -> String {
        let key = self.uuid + "-" + String(self.major) + "-" + String(self.minor);
        return key.uppercased();
    }
}

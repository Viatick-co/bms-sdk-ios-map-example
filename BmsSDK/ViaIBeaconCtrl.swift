//
//  ViaIBeaconCtrl.swift
//  iOsSDK
//
//  Created by Viatick on 20/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

protocol ViaIBeaconCtrlDelegate {
    func viaIBeaconCtrl(controller: ViaIBeaconCtrl, discover viaIBeacon: ViaIBeacon);
    func viaIbeaconCtrl(controller: ViaIBeaconCtrl, rangeBeacons viaIBeacons: [ViaIBeacon]);
    func viaIbeaconCtrl(controller: ViaIBeaconCtrl, didEnterRegion status: Bool);
}

class ViaIBeaconCtrl: NSObject, CBPeripheralManagerDelegate {
    
    var scannedBeacons : Dictionary<String, String> = [:];
    var viaIBeaconRegion: ViaIBeaconRegion?;
    
    var distanceFilterBeacon : Dictionary<String, IBeacon> = [:];
    var filterRange: Double = 0;
    
    var locationManager = CLLocationManager()
    var delegate: ViaIBeaconCtrlDelegate?
    
    var broadcastPeripheralManager : CBPeripheralManager?;
    var broadcastRegion : CLBeaconRegion?;
    
    func initiate(viaIBeaconRegion: ViaIBeaconRegion, distanceFilter: Dictionary<String, IBeacon>, filterRange: Double) {
        self.viaIBeaconRegion = viaIBeaconRegion;
        self.distanceFilterBeacon = distanceFilter;
        self.filterRange = filterRange;
        
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization();
    }
    
    func iBeaconRegion() -> CLBeaconRegion {
        let identifier: String = "ble.viatick.com"
        let uuid = UUID(uuidString: viaIBeaconRegion!.uuid)
        var beaconRegion: CLBeaconRegion;
        if(viaIBeaconRegion!.major == 0 && viaIBeaconRegion!.minor == 0) {
            beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: identifier)
        } else if(viaIBeaconRegion!.minor == 0) {
            beaconRegion = CLBeaconRegion(proximityUUID: uuid!, major: CLBeaconMajorValue(viaIBeaconRegion!.major), identifier: identifier)
        } else {
            beaconRegion = CLBeaconRegion(proximityUUID: uuid!, major: CLBeaconMajorValue(viaIBeaconRegion!.major), minor: CLBeaconMinorValue(viaIBeaconRegion!.minor), identifier: identifier)
        }
        
        beaconRegion.notifyEntryStateOnDisplay = true;
        beaconRegion.notifyOnEntry = true;
        beaconRegion.notifyOnExit = true;
        return beaconRegion;
    }
    
    func startRange() {
        let region: CLBeaconRegion = iBeaconRegion();
        locationManager.startMonitoring(for: region);
        locationManager.startRangingBeacons(in: region);
        
        
    }
    
    func stopRange() {
        if viaIBeaconRegion != nil {
            let region: CLBeaconRegion = iBeaconRegion();
            locationManager.stopMonitoring(for: region);
            locationManager.stopRangingBeacons(in: region);
        }
        
        self.scannedBeacons.removeAll();
    }
    
    func startBroadcast(uuid: String, major: Int, minor: Int) {
        let proximityUUID = UUID(uuidString: uuid);
        
        self.broadcastRegion = CLBeaconRegion(proximityUUID: proximityUUID!, major: CLBeaconMajorValue(major), minor: CLBeaconMajorValue(minor), identifier: "BMS");
        
        self.broadcastPeripheralManager = CBPeripheralManager(delegate: self, queue: nil);
    }
    
    func stopBroadcast() {
        if (self.broadcastPeripheralManager != nil) {
            self.broadcastPeripheralManager!.stopAdvertising();
            self.broadcastPeripheralManager = nil;
        }
    }
    
    func processCLBeacons(beacons: [CLBeacon]) {
        var viaIBeacons: [ViaIBeacon] = [];
        
        for b in beacons {
            let newViaIBeacon: ViaIBeacon = ViaIBeacon(iBeacon: b, maxDistance: 200, isRequested: false, disappearIdx: 0);
            
            let uuid = b.proximityUUID.uuidString;
            let major = b.major;
            let minor = b.minor;
            let key = uuid + "-" + major.stringValue + "-" + minor.stringValue;
            let mainKey = key.uppercased();
            
            let beaconAccuracy: Double = -1 * b.accuracy.distance(to: 0);
            
            if (self.filterRange > 0 && beaconAccuracy > self.filterRange) {
                continue;
            }
            
            if let filterDistance = self.distanceFilterBeacon[mainKey] {
                let distance = filterDistance.distance;
                
                if (distance > 0 && beaconAccuracy > distance) {
                    continue;
                }
            }
            
            let scannedBeacon = self.scannedBeacons[mainKey];
            if scannedBeacon == nil {
                self.scannedBeacons[mainKey] = mainKey;
                delegate?.viaIBeaconCtrl(controller: self, discover: newViaIBeacon);
            }
            
            viaIBeacons.append(newViaIBeacon);
        }
        // print("viaIBeacons", viaIBeacons);
        delegate?.viaIbeaconCtrl(controller: self, rangeBeacons: viaIBeacons);
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            if let broadcastRegion = self.broadcastRegion {
                if let peripheralManager = self.broadcastPeripheralManager {
                    let peripheralData = broadcastRegion.peripheralData(withMeasuredPower: -53);
                    peripheralManager.startAdvertising(((peripheralData as NSDictionary) as! [String : Any]));
                }
            }
        }
    }
}

extension ViaIBeaconCtrl: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // print("didChangeAuthorization", status.rawValue)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // print("didEnterRegion", region.description) // TODO
        delegate?.viaIbeaconCtrl(controller: self, didEnterRegion: true);
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // print("didRangeBeacons", region.description);
        // print("didRangeBeacons", beacons.description);
        processCLBeacons(beacons: beacons);
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // print("didExitRegion", region.description) // TODO
        delegate?.viaIbeaconCtrl(controller: self, didEnterRegion: false);
    }
}

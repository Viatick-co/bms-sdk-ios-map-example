//
//  ViewController.swift
//  TestSDK
//
//  Created by Viatick on 20/5/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import UIKit;
import SafariServices;
import BmsSDK;

class ViewController: UIViewController {
    
    // declare instance of bms controller
    let viaBmsCtrl = ViaBmsCtrl.sharedInstance;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        initMap()
    }
    
    func testSDK() {
        var requestDistanceBeacons:[IBeacon] = [];
//        requestDistanceBeacons.append(beacon2);
        
        // configure bms sdk settings at first
        // to enable alert
        // to enable minisite feature and type of view (AUTO or LIST)
        // to enable customer tracking feature
        // to enable customer attendance feature
        // to enable broadcasst
        // to enable proximity alert
        viaBmsCtrl.setting(alert: true, background: true, site: true, minisitesView: .LIST, autoSiteDuration: 0, tracking: false, enableMQTT: false, attendance: false, checkinDuration: 5, checkoutDuration: 20, requestDistanceBeacons: requestDistanceBeacons, bmsEnvironment: .DEV, beaconRegionRange: 10, beaconRegionUUIDFilter: false, isBroadcasting: false, proximityAlert: false, proximityAlertThreshold: 20, proximityAwayThreshold: 60, proximityRange: 20);
        
        // optional to attach delegate
        // 4 callbacks
        // sdkInited
        // customerInited
        // if attendance is enable
        // checkin and checkout
        viaBmsCtrl.delegate = self;

        // this method must be called at first to do handshake with bms
        // sdkInited callback will be called
        viaBmsCtrl.initSdk(uiViewController: self, sdk_key: "67bcdfca98833eb53bf1958a03b92777317bf7c85a1a8d3b616fb30a761d7d73");
    }
    
    func initMap() {
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        
        viaBmsCtrl.delegate = self;
        
        viaBmsCtrl.initMap(view: self.view!, width: screenWidth, height: screenHeight, sdk_key: "cbbdb337456a549dc9351790b3955970a186b6341ba5e9dfc0b596b4452c51af");
    }
    
    // start sdk servicaze
    @IBAction func startSDK(sender: Any) {
        // these methods are to check sdk initation and bms is running or not
        let bmsRunning = viaBmsCtrl.isBmsRunning();
        let sdkInited = viaBmsCtrl.isSdkInited();
        
        if (!bmsRunning && sdkInited) {
            // this method is to start bms service if it is not running
            // you can call this method to restart without calling initSdk again
            viaBmsCtrl.startBmsService();
        }
    }
    
    // end sdk service
    @IBAction func stopSDK(sender: Any) {
        // this method is to stop the bms service
        viaBmsCtrl.stopBmsService();
    }

}


extension ViewController: ViaBmsCtrlDelegate {
    func onZonesLoaded(zones: [Dictionary<String, Any>]) {
        print("onZonesLoaded", zones)
    }
    
    func onProperZoneRecordsLoaded(zoneRecords: [Dictionary<String, Any>]) {
        print("onProperZoneRecordsLoaded", zoneRecords)
        var markers: [MarkerInput] = []
        markers.append(MarkerInput(zoneName: "Zone A", content: "<p style=\"color: #eb4d4b;\">3</p>"))
        viaBmsCtrl.addMarkers(markers: markers)
    }
    
    func blueDotSimulation() {
        var markers: [MarkerInput] = []
        markers.append(MarkerInput(zoneName: "Zone A", content: ViaBmsCtrl.BLUEDOT_CONTENT))
        viaBmsCtrl.addMarkers(markers: markers)
        //self.viaBmsCtrl.updateBlueDotPosition(zoneName: "Zone B")
        //viaBmsCtrl.updateBlueDotPosition(zoneName: "Zone B")
        DispatchQueue.main.asyncAfter(deadline: .now() + (3)) {
            self.viaBmsCtrl.removeMarkers(markers: ["Zone A"])
            self.viaBmsCtrl.addMarker(zoneName: "Zone B", content: ViaBmsCtrl.BLUEDOT_CONTENT)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (5)) {
            self.viaBmsCtrl.removeMarkers(markers: ["Zone B"])
            self.viaBmsCtrl.addMarker(zoneName: "Zone F", content: ViaBmsCtrl.BLUEDOT_CONTENT)
        }
    }
    
    func addRemoveMarkers() {
        viaBmsCtrl.addMarker(zoneName: "Zone A", content: "<p style=\"color: #eb4d4b;\">1</p>")
        viaBmsCtrl.removeMarkers(markers: ["Zone A"])
        
        var markers: [MarkerInput] = []
        markers.append(MarkerInput(zoneName: "Zone A", content: "<p style=\"color: #eb4d4b;\">1</p>"))
        markers.append(MarkerInput(zoneName: "Zone B", content: "<p style=\"color: #eb4d4b;\">2</p>"))
        viaBmsCtrl.addMarkers(markers: markers)
    }
    
    func onMapInited(status: Bool) {
        print("onMapInited", status)
        if (status) {
            //addRemoveMarkers()
            
            // Comment this on and comment out addRemoveMakers to run the blue dot simulation sample instead
            blueDotSimulation()
        }
    }
    
    func onZoneClicked(zoneName: String) {
        print(zoneName, " is clicked")
    }
    
    func onNewProximityAlert(uuid: String, major: Int, minor: Int, deviceUUID: String) {
        
    }
    
    func onBluetoothStateOn() {
        
    }
    
    func onBluetoothStateOff() {
        
    }
    
    func onAddZoneRecord(uuid: String?, major: Int, minor: Int, newZones: [ViaZone]?) {
        
    }
    
    
    // this will be called when sdk is inited
    // list of zones in the sdk application is passed here
    func sdkInited(inited status: Bool, zones: [ViaZone]) {
        print("sdk inited", status);
        
        // this method must be called in order to enable attendance and tracking feature
        // authorizedZones is optional field
        viaBmsCtrl.initCustomer(identifier: "long_test_01", email: "example@email.com", phone: "+000000000", authorizedZones: []);
    }
    
    func customerInited(inited: Bool) {
        print("customer inited", inited);
    }
    
    func checkin() {
        print("check in callback");
    }
    
    func checkout() {
        print("check out callback");
    }
    
    func onProximityAlert() {
        print("onProximityAlert");
    }
    
    func onDistanceBeacons(beacons: [IBeacon]) {
//        print("distance");
//        for aBeacon in beacons {
//            print("key " + aBeacon.getKey() + " distance " + String(aBeacon.distance));
//        }
    }
    
    func deviceSiteLoaded(loaded: Bool, error: String?) {
        if (error != nil) {
            print("deviceSiteLoaded: " + loaded.description + " with error " + error!);
        } else {
            print("deviceSiteLoaded: " + loaded.description);
        }
    }
}




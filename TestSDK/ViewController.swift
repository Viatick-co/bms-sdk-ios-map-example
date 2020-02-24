//
//  ViewController.swift
//  TestSDK
//
//  Created by Viatick on 20/5/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import UIKit;
import SafariServices;

class ViewController: UIViewController {
    
    // declare instance of bms controller
    let viaBmsCtrl = ViaBmsCtrl.sharedInstance;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        var requestDistanceBeacons:[IBeacon] = [];
        let beacon:IBeacon = IBeacon(uuid: "F7826DA6-4FA2-4E98-8024-BC5B71E0893B", major: 100, minor: 2);
//        let beacon2:IBeacon = IBeacon(uuid: "F7826DA6-4FA2-4E98-8024-BC5B71E0893A", major: 100, minor: 3);
        requestDistanceBeacons.append(beacon);
//        requestDistanceBeacons.append(beacon2);
        
        // configure bms sdk settings at first
        // to enable alert
        // to enable minisite feature and type of view (AUTO or LIST)
        // to enable customer tracking feature
        // to enable customer attendance feature
        // to enable broadcasst
        // to enable proximity alert
        viaBmsCtrl.setting(alert: true, background: true, site: false, minisitesView: .LIST, autoSiteDuration: 0, tracking: false, enableMQTT: false, attendance: true, checkinDuration: 5, checkoutDuration: 20, requestDistanceBeacons: requestDistanceBeacons, bmsEnvironment: .DEV, beaconRegionRange: 10, beaconRegionUUIDFilter: true, isBroadcasting: true, proximityAlert: true, proximityAlertThreshold: 20);
        
        // optional to attach delegate
        // 4 callbacks
        // sdkInited
        // customerInited
        // if attendance is enable
        // checkin and checkout
        viaBmsCtrl.delegate = self;

        // this method must be called at first to do handshake with bms
        // sdkInited callback will be called
        viaBmsCtrl.initSdk(uiViewController: self, sdk_key: "71b20b69d6c313e5a226b910ccac09d35c68caaec7c7303984f8caae0a7fdb25");
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
    
    // this will be called when sdk is inited
    // list of zones in the sdk application is passed here
    func sdkInited(inited status: Bool, zones: [ViaZone]) {
        print("sdk inited", status);
        
        // this method must be called in order to enable attendance and tracking feature
        // authorizedZones is optional field
        viaBmsCtrl.initCustomer(identifier: "long_test_01", email: "example@email.com", phone: "+000000000", authorizedZones: zones);
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
}




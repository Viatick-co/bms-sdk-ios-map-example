//
//  ViaBmsCtrl.swift
//  iOsSDK
//
//  Created by Viatick on 19/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation
import UIKit

public protocol ViaBmsCtrlDelegate {
    func sdkInited(inited status: Bool, zones: [ViaZone]);
    
    func customerInited(inited: Bool);
    
    func checkin();
    
    func checkout();
    
    func onProximityAlert();
    
    func onDistanceBeacons(beacons: [IBeacon]);
}

open class ViaBmsCtrl: NSObject {
    
    public static let sharedInstance = ViaBmsCtrl();
    
    private var SDK_KEY: String?;
    private var SDK_TOKEN: String = "";
    private var SDK_EXPIRATION_TIME: UInt64 = 0;
    private var API_KEY: String = "";
    private var SETTING: ViaSetting = ViaSetting();
    private var CUSTOMER: ViaCustomer?;
    private var IBEACON_REGION: ViaIBeaconRegion = ViaIBeaconRegion()
    private var EDDYSTONE_REGION: ViaEddystoneRegion = ViaEddystoneRegion();
    private var FETCH_INTERVAL: ViaFetchInterval = ViaFetchInterval();
    private var ATTENDANCE : ViaAttendance = ViaAttendance();
    private var PROXIMITY_ALERT : ViaAttendance = ViaAttendance();
    private var ZONES : Dictionary<Int, ViaZone> = [:];
    private var REQUESTED_DISTANCE_BEACONS : Dictionary<String, IBeacon> = [:];
    private var OWNED_BEACONS : Dictionary<String,IBeacon> = [:];
    
    private var sdkInited = false;
    private var bmsRunning = false;
    private var attendanceUpdating = false;
    private var alertUpdating = false;
    private var MINISITES: [ViaMinisite] = [];
    private var currentSite = -1;
    private var inMinisiteAuto = false;
    internal var inMinisiteView = false;
    internal var isModal = false;
    
    private var attendanceTimer: Timer?;
    private var alertTimer: Timer?;
    private var assignedBeacons: Dictionary<String, ViaZoneBeacon> = [:];
    
    public var delegate: ViaBmsCtrlDelegate?;
    
    private let viaIBeaconCtrl = ViaIBeaconCtrl();
    private let bmsApiCtrl = BmsApiCtrl();
    
    private var parentUIViewController: UIViewController?;
    private let viaMinisiteTableViewController: ViaMinisiteTableViewController = ViaMinisiteTableViewController();
    private let viaMinisiteViewController: ViaMinisiteViewController = ViaMinisiteViewController();
    
    private let viaNotificationCenter: ViaNotificationCenter = ViaNotificationCenter();
    private let viaBackgroundTaskCenter: ViaBackgroundTaskCenter = ViaBackgroundTaskCenter();
    private let endpointConfiguration: EndpointConfiguration = EndpointConfiguration();
    
    public func setting(alert: Bool, background: Bool, site: Bool, minisitesView : MinisiteViewType, autoSiteDuration : TimeInterval, tracking: Bool, enableMQTT: Bool, attendance: Bool, checkinDuration: TimeInterval?, checkoutDuration: TimeInterval?, requestDistanceBeacons: [IBeacon]?, bmsEnvironment: BmsEnvironment, beaconRegionRange: Double?, beaconRegionUUIDFilter : Bool, isBroadcasting : Bool, proximityAlert: Bool, proximityAlertThreshold : TimeInterval?) {
        SETTING.enableAlert = alert;
        SETTING.enableBackground = background;
        SETTING.enableSite = site;
        SETTING.autoSite = autoSiteDuration;
        SETTING.minisitesView = minisitesView;
        SETTING.enableTracking = tracking;
        SETTING.enableMQTT = enableMQTT;
        SETTING.attendance = attendance;
        
        if (beaconRegionRange != nil) {
            SETTING.beaconRegionRange = beaconRegionRange!;
        }
        
        SETTING.beaconRegionUUIDFilter = beaconRegionUUIDFilter;
        SETTING.isBroadcasting = isBroadcasting;
        
        if checkinDuration != nil {
            SETTING.checkinDuration = checkinDuration!;
        }
        if checkoutDuration != nil {
            SETTING.checkoutDuration = checkoutDuration!;
        }
        
        self.bmsApiCtrl.initApi(environment: bmsEnvironment);
        
        SETTING.proximityAlert = proximityAlert;
        if (proximityAlertThreshold != nil) {
            SETTING.proximityAlertThreshold = proximityAlertThreshold!;
        }
        
        self.REQUESTED_DISTANCE_BEACONS.removeAll();
        
        if (requestDistanceBeacons != nil) {
            for aBeacon in requestDistanceBeacons! {
                let key = aBeacon.getKey();
                let requestedBeacon = REQUESTED_DISTANCE_BEACONS[key];
                if (requestedBeacon == nil) {
                    REQUESTED_DISTANCE_BEACONS[key] = aBeacon;
                }
            }
            SETTING.enableDistance = true;
        }
    }
    
    private func getToken() -> String {
        let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
        if (SDK_EXPIRATION_TIME <= now && self.SDK_KEY != nil) {
            let tokenResponse = self.bmsApiCtrl.getSdkToken(sdkKey: self.SDK_KEY!);
            let success = tokenResponse["success"] as! Bool;
            
            if success {
                SDK_TOKEN = tokenResponse["sdkToken"] as! String;
                SDK_EXPIRATION_TIME = tokenResponse["expirationTime"] as! UInt64;
            } else {
                SDK_TOKEN = "";
                SDK_EXPIRATION_TIME = 0;
            }
        }
        
        return SDK_TOKEN;
    }
    
    public func initSdk(uiViewController: UIViewController, sdk_key: String) {
        parentUIViewController = uiViewController;
        SDK_KEY = sdk_key;
        
        DispatchQueue.background(background: {
            let token = self.getToken();
            if !token.isEmpty {
                let sdkInfoData = self.bmsApiCtrl.getSdkInfo(sdkToken: token);
                let success = sdkInfoData["success"] as! Bool;
                if success {
                    if let uuid = sdkInfoData["uuidRegion"] {
                        let sdkBroadcastUUID = sdkInfoData["sdkBroadcastUUID"] as! String;
                        
                        if (self.SETTING.beaconRegionUUIDFilter == true && sdkBroadcastUUID != "") {
                            self.IBEACON_REGION.uuid = sdkBroadcastUUID;
                        } else {
                            self.IBEACON_REGION.uuid = uuid as! String;
                        }
                        
                        self.API_KEY = sdkInfoData["apiKey"] as! String;
                        self.ZONES = sdkInfoData["zones"] as! Dictionary<Int, ViaZone>;
                        self.OWNED_BEACONS = sdkInfoData["ownBeacons"] as! Dictionary<String, IBeacon>;
                        
                        self.viaNotificationCenter.initiate();
                        self.sdkInited = true;
                    }
                }
            } else {
                self.sdkInited = false;
            }
            
            let zones = Array(self.ZONES.values);
            
            self.delegate?.sdkInited(inited: self.sdkInited, zones: zones);
        });
    }
    
    public func isSdkInited() -> Bool {
        return self.sdkInited;
    }
    
    public func initCustomer(identifier: String, email: String, phone: String, authorizedZones: [ViaZone]) {
        DispatchQueue.background(background: {
            var inited = false;
            
            let token = self.getToken();
            if !token.isEmpty {
                let model = UIDevice.current.type.rawValue;
                let os = "iOs";
                let version = UIDevice.current.systemVersion;
                let remark = model + " : " + os + " : " + version;
                
                if let registeredCustomer = self.bmsApiCtrl.processCustomer(sdkToken: token, identifier: identifier, phone: phone, email: email, remark: remark, os: "iOs", authorizedZones: authorizedZones, isBroadcasting: self.SETTING.isBroadcasting) {
                    
                    self.CUSTOMER = registeredCustomer;
                    
                    self.assignedBeacons.removeAll();
                    
                    let authorizedZones = self.bmsApiCtrl.getAuthorizedZones(sdkToken: token, identifier: identifier);
                    
                    for zoneId in authorizedZones {
                        let aZone = self.ZONES[zoneId];
                        if aZone != nil {
                            let beacons = aZone!.beacons;
                            
                            for assignedBeacon in beacons {
                                let beaconKey = assignedBeacon.uuid + "-" + String(assignedBeacon.major) + "-" + String(assignedBeacon.minor);
                                self.assignedBeacons[beaconKey] = assignedBeacon;
                            }
                        }
                    }
                    
                    inited = true;
                }
            }
            
            self.delegate?.customerInited(inited: inited);
        });
    }
    
    public func isCustomerInited() -> Bool {
        return self.CUSTOMER != nil;
    }
    
    public func startBmsService() {
        if (self.sdkInited && !self.bmsRunning) {
            self.bmsRunning = true;
            if SETTING.enableBackground {
                if viaBackgroundTaskCenter.backgroundTask != UIBackgroundTaskIdentifier.invalid {
                    viaBackgroundTaskCenter.endBackgroundTask();
                }
                viaBackgroundTaskCenter.registerBackgroundTask();
            }
            
            viaIBeaconCtrl.delegate = self;
            viaIBeaconCtrl.initiate(viaIBeaconRegion: IBEACON_REGION, distanceFilter: OWNED_BEACONS, filterRange: SETTING.beaconRegionRange);
            viaIBeaconCtrl.startRange();
            
            if (SETTING.isBroadcasting) {
                if let uuid = self.CUSTOMER!.uuid {
                    let major = self.CUSTOMER!.major;
                    let minor = self.CUSTOMER!.minor;
                    
                    viaIBeaconCtrl.startBroadcast(uuid: uuid, major: major!, minor: minor!);
                }
            }
            
            if SETTING.attendance {
                self.startCheckAttendanceTimer();
            }
            
            if SETTING.proximityAlert {
                self.startCheckAlertTimer();
            }
        }
    }
    
    public func stopBmsService() {
        if (self.bmsRunning) {
            if SETTING.enableBackground {
                if viaBackgroundTaskCenter.backgroundTask != UIBackgroundTaskIdentifier.invalid {
                    viaBackgroundTaskCenter.endBackgroundTask();
                }
            }
            viaIBeaconCtrl.stopRange();
            
            if (SETTING.isBroadcasting) {
                viaIBeaconCtrl.stopBroadcast();
            }
            
            MINISITES.removeAll();
            self.isModal = false;
            
            self.ATTENDANCE.status = .CHECKOUT;
            self.stopCheckAttendanceTimer();
            self.stopCheckAlertTimer();
            self.bmsRunning = false;
        }
    }
    
    public func isBmsRunning() -> Bool {
        return self.bmsRunning;
    }
    
    private func siteRequest(viaIBeacon: ViaIBeacon) {
        if (self.CUSTOMER != nil) {
            let uuid = viaIBeacon.iBeacon.proximityUUID.uuidString;
            let major = viaIBeacon.iBeacon.major;
            let minor = viaIBeacon.iBeacon.minor;
            
            DispatchQueue.background(background: {
                let token = self.getToken();
                if !token.isEmpty {
                    let minisite = self.bmsApiCtrl.getMinisite(sdkToken: token, uuid: uuid, major: major, minor: minor);
                    
                    if (minisite != nil) {
                        self.siteRequestHandler(viaMinisite: minisite!);
                    }
                }
            });
        }
    }
    
    private func siteRequestHandler(viaMinisite: ViaMinisite) {
        let index = indexOf(viaMinisites: MINISITES, viaMinisite: viaMinisite);
        if index == -1 {
            var able = false;
            
            let type = viaMinisite.type;
            let id = viaMinisite.id;
            if (type == MinisiteType.VOTING) {
                let token = self.getToken();
                able = bmsApiCtrl.checkVoting(sdkToken: token, customer: self.CUSTOMER!.customerId, minisite: id);
            } else if (type == MinisiteType.POLLING) {
                let token = self.getToken();
                able = bmsApiCtrl.checkVoting(sdkToken: token, customer: self.CUSTOMER!.customerId, minisite: id);
            } else {
                able = SETTING.minisitesView == .LIST || type != .DEEP_LINK;
            }
            
            if able {
                MINISITES.append(viaMinisite);
                
                if SETTING.enableAlert {
                    let title = viaMinisite.title;
                    let description = viaMinisite.description;
                    let notificationImg = viaMinisite.notificationImg;
                    viaNotificationCenter.shootNotification(title: title, body: description, notificationImg: notificationImg);
                }
                
                if SETTING.minisitesView == .LIST {
                    self.openMinisiteTable();
                } else {
                    self.openMinisiteView();
                }
            }
        }
    }
    
    internal func getSessionLog(minisite: inout ViaMinisite) {
        let token = self.getToken();
        let customerId = self.CUSTOMER!.customerId;
        let minisiteId = minisite.id;
        let beaconId = minisite.beacon;
        
        let logId = self.bmsApiCtrl.createSessionLog(sdkToken: token, customer: customerId, minisite: minisiteId, beacon: beaconId);
        if logId > 0 {
            minisite.logId = logId;
        }
    }
    
    internal func endSessionLog(minisite: ViaMinisite) {
        DispatchQueue.background(background: {
            let logId = minisite.logId;
            if logId ?? 0 > 0 {
                let token = self.getToken();
                self.bmsApiCtrl.updateSessionLog(sdkToken: token, sessionLogId: logId!);
            }
        });
    }
    
    private func trackingRequest(viaIBeacons: [ViaIBeacon]) {
        if (self.CUSTOMER != nil) {
            DispatchQueue.background(background: {
               for vb in viaIBeacons {
                   let distance: Double = -1 * vb.iBeacon.accuracy.distance(to: 0);
                   if distance > 0 {
                       let uuid = vb.iBeacon.proximityUUID.uuidString;
                       let major = vb.iBeacon.major;
                       let minor = vb.iBeacon.minor;
                    let identifier = self.CUSTOMER!.identifier;
                       let phone = self.CUSTOMER!.phone;
                       let email = self.CUSTOMER!.email;
                       let remark = self.CUSTOMER!.remark;
                       
                       if (self.SETTING.enableMQTT) {
                        self.bmsApiCtrl.coreTrackingWithMQTT(apiKey: self.API_KEY, uuid: uuid, major: major, minor: minor, identifier: identifier, phone: phone, email: email, remark: remark, distance: distance);
                       } else {
                          self.bmsApiCtrl.coreTracking(apiKey: self.API_KEY, uuid: uuid, major: major, minor: minor, identifier: identifier, phone: phone, email: email, remark: remark, distance: distance);
                       }
                   }
               }
            });
        }
    }
    
    private func updateBeaconDistance(viaIBeacons: [ViaIBeacon]) {
        DispatchQueue.background(background: {
            var responseBeacons:[IBeacon] = [];
            for vb in viaIBeacons {
                let distance: Double = -1 * vb.iBeacon.accuracy.distance(to: 0);
                if distance > 0 {
                    let uuid = vb.iBeacon.proximityUUID.uuidString;
                    let major = vb.iBeacon.major;
                    let minor = vb.iBeacon.minor;
                    let key = uuid + "-" + major.stringValue + "-" + minor.stringValue;
                    let mainKey = key.uppercased();
                    
                    if var responseBeacon = self.REQUESTED_DISTANCE_BEACONS[mainKey] {
                        responseBeacon.distance = distance;
                        
                        responseBeacons.append(responseBeacon);
                    }
                }
            }
            
            if (responseBeacons.count > 0) {
                self.delegate?.onDistanceBeacons(beacons: responseBeacons);
            }
        });
    }
    
    private func startCheckAttendanceTimer() {
        self.attendanceTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkAttendance), userInfo: nil, repeats: true);
    }
    
    private func stopCheckAttendanceTimer() {
        self.attendanceTimer?.invalidate();
    }
    
    private func startCheckAlertTimer() {
         self.alertTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkAlert), userInfo: nil, repeats: true);
    }
    
    private func stopCheckAlertTimer() {
        self.alertTimer?.invalidate();
    }
    
    @objc func checkAttendance() {
        let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
        
        let stt = self.ATTENDANCE.status;
        if (stt == .PRE_CHECKIN || stt == .CHECKIN) {
            let lastAttendance = self.ATTENDANCE.attendanceTime;
            let difference = now - lastAttendance;
            if difference >= UInt64((self.SETTING.checkoutDuration * 1000)) {
                if (stt == .CHECKIN) {
                    DispatchQueue.background(background: {
                        let token = self.getToken();
                        let checkout = self.bmsApiCtrl.checkout(sdkToken: token, attendanceId: self.ATTENDANCE.attendanceId, time: now.iso8601);
                        
                        if (checkout) {
                            self.delegate?.checkout();
                        }
                    });
                }
                
                self.ATTENDANCE.status = AttendanceStatus.CHECKOUT;
            }
        }
    }
    
    @objc func checkAlert() {
        let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
        
        let stt = self.PROXIMITY_ALERT.status;
        if (stt == .PRE_CHECKIN || stt == .CHECKIN) {
            let lastAttendance = self.PROXIMITY_ALERT.attendanceTime;
            let difference = now - lastAttendance;
            if difference >= UInt64((60 * 1000)) {
                self.PROXIMITY_ALERT.status = AttendanceStatus.CHECKOUT;
            }
        }
    }
    
    private func updateDeviceAttendance(viaIBeacons: [ViaIBeacon]) {
        if (self.CUSTOMER != nil && !self.attendanceUpdating) {
            DispatchQueue.background(background: {
                self.attendanceUpdating = true;
                
                let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
                var checkin = false;
                
                for beacon in viaIBeacons {
                    let iBeacon = beacon.iBeacon;
                    
                    let distance: Double = -1 * iBeacon.accuracy.distance(to: 0);
                    if distance > 0 {
                        let uuid = iBeacon.proximityUUID.uuidString;
                        let major = iBeacon.major;
                        let minor = iBeacon.minor;
                        let key = uuid + "-" + major.stringValue + "-" + minor.stringValue;
                        
                        let assignedBeacon = self.assignedBeacons[key];
                        if assignedBeacon != nil {
                            let attendanceStt = self.ATTENDANCE.status;
                            
                            switch attendanceStt {
                                case .CHECKOUT:
                                    self.ATTENDANCE.status = .PRE_CHECKIN;
                                    self.ATTENDANCE.attendanceTime = now;
                                    self.ATTENDANCE.firstAttendance = now;
                                    break;
                                case .PRE_CHECKIN:
                                    let firstAttendance = self.ATTENDANCE.firstAttendance;
                                    let difference = now - firstAttendance;
                                    if difference >= UInt64((self.SETTING.checkinDuration * 1000)) {
                                        self.ATTENDANCE.status = .CHECKIN;
                                        checkin = true;
                                    }
                                    self.ATTENDANCE.attendanceTime = now;
                                    break;
                                case .CHECKIN:
                                    self.ATTENDANCE.attendanceTime = now;
                                    break;
                            }
                            
                            break;
                        }
                    }
                }
                
                if checkin {
                    let token = self.getToken();
                   let attendanceId = self.bmsApiCtrl.checkin(sdkToken: token, customer: self.CUSTOMER!.customerId, time: now.iso8601);
                   if attendanceId != nil {
                       self.ATTENDANCE.attendanceId = attendanceId!;
                       self.delegate?.checkin();
                   }
                }
                self.attendanceUpdating = false;
            });
        }
    }
    
    private func updateProximityAlert(viaIBeacons: [ViaIBeacon]) {
       if (self.CUSTOMER != nil && !self.alertUpdating) {
           DispatchQueue.background(background: {
               self.alertUpdating = true;
               
               let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
               var checkin = false;
                if (viaIBeacons.count > 0) {
                    let attendanceStt = self.PROXIMITY_ALERT.status;
                                  
                      switch attendanceStt {
                          case .CHECKOUT:
                              self.PROXIMITY_ALERT.status = .PRE_CHECKIN;
                              self.PROXIMITY_ALERT.attendanceTime = now;
                              self.PROXIMITY_ALERT.firstAttendance = now;
                              break;
                          case .PRE_CHECKIN:
                          
                              let firstAttendance = self.PROXIMITY_ALERT.firstAttendance;
                              let difference = now - firstAttendance;
                              if difference >= UInt64((self.SETTING.proximityAlertThreshold * 1000)) {
                                  self.PROXIMITY_ALERT.status = .CHECKIN;
                                  checkin = true;
                              }
                              self.PROXIMITY_ALERT.attendanceTime = now;
                              break;
                          case .CHECKIN:
                              self.PROXIMITY_ALERT.attendanceTime = now;
                              break;
                      }
                }
              
               if checkin {
//                   let token = self.getToken();
//                  let attendanceId = self.bmsApiCtrl.checkin(sdkToken: token, customer: self.CUSTOMER!.customerId, time: now.iso8601);
//                  if attendanceId != nil {
//                      self.ATTENDANCE.attendanceId = attendanceId!;
                      
//                  }
                
                let iBeacon = viaIBeacons[0].iBeacon;
                let uuid = iBeacon.proximityUUID.uuidString;
                let major = iBeacon.major.intValue;
                let minor = iBeacon.minor.intValue;
                
                let token = self.getToken();
                let alertId = self.bmsApiCtrl.createProximityAlert(sdkToken: token, customer: self.CUSTOMER!.customerId, uuid: uuid, major: major, minor: minor);
                
                if alertId != nil {
                    self.delegate?.onProximityAlert();
                }
               }
               self.alertUpdating = false;
           });
       }
   }
    
    func isInMinisiteView() -> Bool {
        return self.inMinisiteView;
    }
    
    private func openMinisiteTable() {
        DispatchQueue.main.async {
            if self.isModal {
                self.viaMinisiteTableViewController.update(minisites: self.MINISITES);
            } else {
                self.viaMinisiteTableViewController.initiate(viaBmsCtrl: self, minisites: self.MINISITES, customer: self.CUSTOMER!, apiKey: self.API_KEY);
                self.viaMinisiteTableViewController.modalTransitionStyle = UIModalTransitionStyle.coverVertical;
                self.parentUIViewController?.present(self.viaMinisiteTableViewController, animated: true, completion: nil);
                self.isModal = true;
            }
        }
    }
    
    private func startAuto() {
        if (!self.inMinisiteAuto) {
            self.inMinisiteAuto = true;
            DispatchQueue.main.asyncAfter(deadline: .now() + SETTING.autoSite, execute: self.autoNext);
        }
    }
    
    @objc func autoNext() {
        self.nextMinisite();
    }
    
    private func nextMinisite() {
        let total = self.MINISITES.count;
        let tempTotal = total - 1;
        let autoSite = SETTING.autoSite > 0;
        if (total > 0 && self.currentSite < tempTotal) {
            self.currentSite += 1;
            self.updateMinisiteView();
            
            if (autoSite) {
                self.inMinisiteAuto = false;
                self.startAuto();
            }
        } else {
            if (autoSite == false) {
                self.viaMinisiteViewController.dismiss(animated: true, completion: nil);
            }
        }
    }
    
    private func openMinisiteView() {
        let autoSite = self.SETTING.autoSite > 0;
        if (!self.inMinisiteView) {
            let noMinisites = self.MINISITES.count - 1;
            if (noMinisites > self.currentSite) {
                self.inMinisiteView = true;
                
                DispatchQueue.main.async {
                    self.currentSite += 1;
                    let minisite = self.MINISITES[self.currentSite];
                    
                    if (autoSite) {
                        self.viaMinisiteViewController.initiate(viaBmsCtrl: self, minisite: minisite, customer: self.CUSTOMER!, apiKey: self.API_KEY, close: nil);
                    } else {
                        self.viaMinisiteViewController.initiate(viaBmsCtrl: self, minisite: minisite, customer: self.CUSTOMER!, apiKey: self.API_KEY, close: self.nextMinisite);
                    }
                    
                    self.viaMinisiteViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal;
                    self.parentUIViewController?.present(self.viaMinisiteViewController, animated: true, completion: nil);
                }
            }
        } else if autoSite {
            self.startAuto();
        }
    }
    
    private func updateMinisiteView() {
        DispatchQueue.main.async {
            if (!self.viaMinisiteViewController.isBeingPresented) {
                let minisite = self.MINISITES[self.currentSite];
                self.viaMinisiteViewController.update(minisite: minisite);
            }
        }
    }
    
    private func indexOf(viaMinisites: [ViaMinisite], viaMinisite: ViaMinisite) -> Int {
        var index: Int = -1;
        for (i, m) in viaMinisites.enumerated() {
            if m.same(viaMinisite: viaMinisite) {
                index = i;
                break
            }
        }
        return index
    }
}

extension ViaBmsCtrl: ViaIBeaconCtrlDelegate {
    func viaIBeaconCtrl(controller: ViaIBeaconCtrl, discover viaIBeacon: ViaIBeacon) {
        if SETTING.enableSite {
            siteRequest(viaIBeacon: viaIBeacon);
        }
    }
    
    func viaIbeaconCtrl(controller: ViaIBeaconCtrl, rangeBeacons viaIBeacons: [ViaIBeacon]) {
        if SETTING.enableTracking {
            trackingRequest(viaIBeacons: viaIBeacons);
        }
        
        if SETTING.attendance {
            updateDeviceAttendance(viaIBeacons: viaIBeacons);
        }
        
        if SETTING.proximityAlert {
            updateProximityAlert(viaIBeacons: viaIBeacons);
        }
        
        if SETTING.enableDistance {
            updateBeaconDistance(viaIBeacons: viaIBeacons);
        }
    }
    
    func viaIbeaconCtrl(controller: ViaIBeaconCtrl, didEnterRegion status: Bool) {
        viaNotificationCenter.shootNotification(title: "enter", body: status.description, notificationImg: nil);
    }
}

extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}

internal enum Model : String {
    case simulator   = "simulator/sandbox",
    iPod1            = "iPod 1",
    iPod2            = "iPod 2",
    iPod3            = "iPod 3",
    iPod4            = "iPod 4",
    iPod5            = "iPod 5",
    iPad2            = "iPad 2",
    iPad3            = "iPad 3",
    iPad4            = "iPad 4",
    iPhone4          = "iPhone 4",
    iPhone4S         = "iPhone 4S",
    iPhone5          = "iPhone 5",
    iPhone5S         = "iPhone 5S",
    iPhone5C         = "iPhone 5C",
    iPadMini1        = "iPad Mini 1",
    iPadMini2        = "iPad Mini 2",
    iPadMini3        = "iPad Mini 3",
    iPadAir1         = "iPad Air 1",
    iPadAir2         = "iPad Air 2",
    iPadPro9_7       = "iPad Pro 9.7\"",
    iPadPro9_7_cell  = "iPad Pro 9.7\" cellular",
    iPadPro10_5      = "iPad Pro 10.5\"",
    iPadPro10_5_cell = "iPad Pro 10.5\" cellular",
    iPadPro12_9      = "iPad Pro 12.9\"",
    iPadPro12_9_cell = "iPad Pro 12.9\" cellular",
    iPhone6          = "iPhone 6",
    iPhone6plus      = "iPhone 6 Plus",
    iPhone6S         = "iPhone 6S",
    iPhone6Splus     = "iPhone 6S Plus",
    iPhoneSE         = "iPhone SE",
    iPhone7          = "iPhone 7",
    iPhone7plus      = "iPhone 7 Plus",
    iPhone8          = "iPhone 8",
    iPhone8plus      = "iPhone 8 Plus",
    iPhoneX          = "iPhone X",
    iPhoneXS         = "iPhone XS",
    iPhoneXSmax      = "iPhone XS Max",
    iPhoneXR         = "iPhone XR",
    iPhone11         = "iPhone 11",
    iPhone11Pro      = "iPhone 11 Pro",
    iPhone11ProMax   = "iPhone 11 Pro Max",
    unrecognized     = "?unrecognized?"
}

extension UIDevice {
    internal var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)

            }
        }
        let modelMap : [ String : Model ] = [
            "i386"       : .simulator,
            "x86_64"     : .simulator,
            "iPod1,1"    : .iPod1,
            "iPod2,1"    : .iPod2,
            "iPod3,1"    : .iPod3,
            "iPod4,1"    : .iPod4,
            "iPod5,1"    : .iPod5,
            "iPad2,1"    : .iPad2,
            "iPad2,2"    : .iPad2,
            "iPad2,3"    : .iPad2,
            "iPad2,4"    : .iPad2,
            "iPad2,5"    : .iPadMini1,
            "iPad2,6"    : .iPadMini1,
            "iPad2,7"    : .iPadMini1,
            "iPhone3,1"  : .iPhone4,
            "iPhone3,2"  : .iPhone4,
            "iPhone3,3"  : .iPhone4,
            "iPhone4,1"  : .iPhone4S,
            "iPhone5,1"  : .iPhone5,
            "iPhone5,2"  : .iPhone5,
            "iPhone5,3"  : .iPhone5C,
            "iPhone5,4"  : .iPhone5C,
            "iPad3,1"    : .iPad3,
            "iPad3,2"    : .iPad3,
            "iPad3,3"    : .iPad3,
            "iPad3,4"    : .iPad4,
            "iPad3,5"    : .iPad4,
            "iPad3,6"    : .iPad4,
            "iPhone6,1"  : .iPhone5S,
            "iPhone6,2"  : .iPhone5S,
            "iPad4,1"    : .iPadAir1,
            "iPad4,2"    : .iPadAir2,
            "iPad4,4"    : .iPadMini2,
            "iPad4,5"    : .iPadMini2,
            "iPad4,6"    : .iPadMini2,
            "iPad4,7"    : .iPadMini3,
            "iPad4,8"    : .iPadMini3,
            "iPad4,9"    : .iPadMini3,
            "iPad6,3"    : .iPadPro9_7,
            "iPad6,11"   : .iPadPro9_7,
            "iPad6,4"    : .iPadPro9_7_cell,
            "iPad6,12"   : .iPadPro9_7_cell,
            "iPad6,7"    : .iPadPro12_9,
            "iPad6,8"    : .iPadPro12_9_cell,
            "iPad7,3"    : .iPadPro10_5,
            "iPad7,4"    : .iPadPro10_5_cell,
            "iPhone7,1"  : .iPhone6plus,
            "iPhone7,2"  : .iPhone6,
            "iPhone8,1"  : .iPhone6S,
            "iPhone8,2"  : .iPhone6Splus,
            "iPhone8,4"  : .iPhoneSE,
            "iPhone9,1"  : .iPhone7,
            "iPhone9,2"  : .iPhone7plus,
            "iPhone9,3"  : .iPhone7,
            "iPhone9,4"  : .iPhone7plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,2" : .iPhone8plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSmax,
            "iPhone11,6" : .iPhoneXSmax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax
        ]

    if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            return model
        }
        return Model.unrecognized
    }
}

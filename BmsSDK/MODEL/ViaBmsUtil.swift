//
//  ViaBmsStructs.swift
//  BLE MS SDK
//
//  Created by Bie Yaqing on 24/4/18.
//  Copyright © 2018 Bie Yaqing. All rights reserved.
//

import Foundation

internal struct ViaSetting {
    var enableAlert: Bool;
    var enableBackground: Bool;
    var enableSite: Bool;
    var minisitesView: MinisiteViewType;
    var autoSite:TimeInterval;
    var enableTracking: Bool;
    var enableMQTT: Bool;
    var attendance : Bool;
    var checkinDuration : TimeInterval;
    var checkoutDuration : TimeInterval;
    var enableDistance : Bool;
    var bmsEnvironment: BmsEnvironment;
    var beaconRegionRange : Double;
    var beaconRegionUUIDFilter : Bool;
    var isBroadcasting : Bool;
    var proximityAlert : Bool;
    var proximityAlertThreshold : TimeInterval;
    init() {
        enableAlert = false;
        enableBackground = false;
        enableSite = false;
        autoSite = 0;
        minisitesView = MinisiteViewType.LIST;
        enableTracking = false;
        enableMQTT = true;
        attendance = false;
        checkinDuration = 15;
        checkoutDuration = 15;
        enableDistance = false;
        bmsEnvironment = .DEV;
        beaconRegionRange = 0;
        beaconRegionUUIDFilter = false;
        isBroadcasting = false;
        proximityAlert = false;
        proximityAlertThreshold = 15;
    }
}

internal struct ViaIBeaconRegion {
    var uuid: String;
    var major: Int;
    var minor: Int;
    init() {
        uuid = "00000000-0000-0000-0000-000000000000";
        major = 0;
        minor = 0;
    }
}

internal struct ViaEddystoneRegion {
    var namespace: String;
    var instance: String;
    init() {
        namespace = "00000000000000000000";
        instance = "000000000000";
    }
}

internal struct ViaFetchInterval {
    var attendance: Int;
    var tracking: Int;
    init() {
        attendance = 0;
        tracking = 0;
    }
}

internal struct ViaCustomer {
    var customerId: Int;
    var identifier: String;
    var email: String;
    var phone: String;
    var remark: String;
    var os: String;
    var uuid: String?;
    var major: Int?;
    var minor: Int?;
    
    init(customerId: Int, identifier: String, email: String, phone: String, remark: String, os: String, uuid: String?, major: Int?, minor: Int?) {
        self.customerId = customerId;
        self.identifier = identifier;
        self.email = email;
        self.phone = phone;
        self.remark = remark;
        self.os = os;
        self.uuid = uuid;
        self.major = major;
        self.minor = minor;
    }
}

internal enum ViaKey: String {
    case APIKEY = "apiKey";
    case RANGE = "range";
    case IBEACON = "iBeacon";
    case UUID = "uuid";
    case MAJOR = "major";
    case MINOR = "minor";
    case DISTANCE = "distance";
    case EDDYSTONE = "eddystone";
    case NAMESPACE = "namespace";
    case INSTANCE = "instance";
    case FETCHRATE = "fetchRate";
    case ATTENDANCE = "attendance";
    case TRACKING = "tracking";
    case CUSTOMERID = "customerId";
    case IDENTIFIER = "identifier";
    case PHONE = "phone";
    case EMAIL = "email";
    case REMARK = "remark";
    case DATA = "data";
    case ATTENDANCEID = "attendanceId";
    case TRACKINGID = "trackingId";
    case DATE = "date";
    case TITLE = "title";
    case DESCRIPTION = "description";
    case URL = "url";
    case COVER = "cover";
    case TYPE = "type";
}

internal enum ViaApiName: String {
    case APP_HANDSHAKE = "APP_HANDSHAKE";
    case CORE_CUSTOMER = "CORE_CUSTOMER";
    case CORE_SITE = "CORE_SITE";
    case CORE_TRACKING = "CORE_TRACKING";
    case NOT_FOUND = "NOT_FOUND";
}

internal enum ViaHeaderKey: String {
    case API_KEY = "Api-Key";
    case SDK_KEY = "SDK-Key";
    case CLIENT_ID = "client_id";
    case SCOPE = "scope";
    case GRANT_TYPE = "grant_type";
}

internal struct EndpointConfiguration {
    var clientId: String;
    var credentialGrantType: String;
    init() {
        clientId = "r476mmg5k60rkblvidria8jv6";
        credentialGrantType = "client_credentials";
    }
}

internal enum MinisiteType: String {
    case ADVERTISEMENT = "advertisement";
    case COUPON = "coupon";
    case DEEP_LINK = "deepLink";
    case VOTING = "voting";
    case POLLING = "polling";
}

internal enum AttendanceStatus: String {
    
    case PRE_CHECKIN = "preCheckin";
    case CHECKIN = "checkin";
    case CHECKOUT = "checkout";
    
}

public enum MinisiteViewType: String {
    case LIST = "list_view";
    case AUTO = "auto_view";
}

internal extension UInt64 {
    var iso8601: String {
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(self)/1000);
        let dateFormatter = DateFormatter();
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        return dateFormatter.string(from: dateVar);
    }
}

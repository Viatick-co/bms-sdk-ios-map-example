//
//  BmsApiCtrl.swift
//  iOsSDK
//
//  Created by Viatick on 20/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation

extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

internal class BmsApiCtrl: NSObject {
    let API_URL = "https://bms-api.viatick.com";
    var API_ENDPOINT:String;
    let SDK_TOKEN_PATH = "/sdk/oauth2/token";
    let SDK_PATH = "/api/restful";
    let CORE_TRACKING_PATH = "/api/core/tracking";
    let CORE_MQTT_TRACKING_PATH = "/api/core/mqtt/tracking";
    
    let endpointConfiguration: EndpointConfiguration = EndpointConfiguration();
    
    override init() {
        API_ENDPOINT = API_URL + "/dev";
    }
    
    func initApi(environment: BmsEnvironment!) {
        switch environment {
            case .DEV:
                API_ENDPOINT = API_URL + "/dev";
                break;
            case .CHINA:
                API_ENDPOINT = API_URL + "/cn";
                break;
            case .PROD:
                API_ENDPOINT = API_URL + "/main";
                break;
            default:
                break;
        }
    }
    
    func getSdkToken(sdkKey: String) -> Dictionary<String,  Any> {
        var success = false;
        var sdkToken: String = "";
        var expirationTime: UInt64 = 0;
        
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_TOKEN_PATH)!;
        
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let headers: Dictionary<String, String> = [
            ViaHeaderKey.GRANT_TYPE.rawValue: endpointConfiguration.credentialGrantType,
            ViaHeaderKey.SCOPE.rawValue: sdkKey
        ];
        request.allHTTPHeaderFields = headers;
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    success = true;
                    
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    sdkToken = (dataDictionary["access_token"] as? String)!;
                    
                    expirationTime = UInt64(NSDate().timeIntervalSince1970 * 1000) + 3000000;
                } catch {
                }
            } else {
            }
        }
        
        let rpData:Dictionary<String, Any> = [
            "sdkToken" : sdkToken,
            "success" : success,
            "expirationTime" : expirationTime
        ];
        
        return rpData;
    }
    
    func getSdkInfo(sdkToken: String) -> Dictionary<String, Any> {
        var fetchRate:Int = 0;
        var uuidRegion:String = "";
        var sdkBroadcastUUID:String = "";
        var success = false;
        var apiKey:String = "";
        var zones: Dictionary<Int, ViaZone> = [:];
        var ownBeacons: Dictionary<String, IBeacon> = [:];
        
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let argumentData:Dictionary<String, String> = [:];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "sdkGetInfo",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    fetchRate = (dataDictionary["fetchRate"] as? Int)!;
                    
                    if let distanceDic : Dictionary<String, Any> = dataDictionary["distance"] as? Dictionary<String, Any> {
                        if let beaconArray: [Dictionary<String, Any>] = distanceDic["iBeacon"] as? [Dictionary<String, Any>] {
                            for beaconDic in beaconArray {
                                let uuid = beaconDic["uuid"] as! String;
                                let major = beaconDic["major"] as! Int;
                                let minor = beaconDic["minor"] as! Int;
                                let distance = beaconDic["distance"] as! Double;
                                
                                var iBeacon = IBeacon(uuid: uuid, major: major, minor: minor);
                                iBeacon.distance = distance;
                                
                                let key = iBeacon.getKey();
                                ownBeacons[key] = iBeacon;
                            }
                        }
                    }
                    
                    if let broadcastUUID = dataDictionary["sdkBroadcastUUID"] as? String {
                        sdkBroadcastUUID = broadcastUUID;
                    }
                    
                    if let range: Dictionary<String, Any> = dataDictionary["range"] as? Dictionary<String, Any> {
                        if let ibeacon: Dictionary<String, Any> = range["iBeacon"] as? Dictionary<String, Any> {
                            if let uuid = ibeacon["uuid"] {
                                uuidRegion = uuid as! String;
                                apiKey = dataDictionary["apiKeyHash"] as! String;
                                
                                let zoneArray = dataDictionary["zones"] as! [Dictionary<String,Any>];
                                for aZone in zoneArray {
                                    let zoneId = aZone["zoneId"] as! Int;
                                    let name = aZone["name"] as? String;
                                    let remark = aZone["remark"] as? String;
                                    let image = aZone["image"] as? String;
                                    var beacons:[ViaZoneBeacon] = [];
                                    
                                    let beaconArray = aZone["iBeacons"] as? [Dictionary<String, Any>];
                                    if beaconArray != nil {
                                        for beaconDictionary in beaconArray! {
                                            let deviceId = beaconDictionary["deviceId"] as! Int;
                                            let uuid = beaconDictionary["uuid"] as! String;
                                            let major = beaconDictionary["major"] as! Int;
                                            let minor = beaconDictionary["minor"] as! Int;
                                            
                                            let beacon = ViaZoneBeacon(deviceId: deviceId, uuid: uuid, major: major, minor: minor);
                                            beacons.append(beacon);
                                        }
                                    }
                                    
                                    let newZone = ViaZone(zoneId: zoneId, name: name, remark: remark, image: image, beacons: beacons);
                                    
                                    zones[zoneId] = newZone;
                                }
                                
                                success = true;
                            }
                        }
                    }
                    
                } catch {
                }
            } else {
            }
        }
        
        let rpData:Dictionary<String, Any> = [
            "fetchRate" : fetchRate,
            "success" : success,
            "uuidRegion" : uuidRegion,
            "sdkBroadcastUUID": sdkBroadcastUUID,
            "zones" : zones,
            "apiKey" : apiKey,
            "ownBeacons" : ownBeacons
        ];
        
        return rpData;
    }
    
    func getMinisite(sdkToken: String, uuid: String, major: NSNumber, minor: NSNumber) -> ViaMinisite? {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let argumentData:Dictionary<String, String> = [
            "id1": uuid,
            "id2" : major.stringValue,
            "id3" : minor.stringValue
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "sdkSite",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    let url = dataDictionary["url"] as! String;
                    let title = dataDictionary["title"] as! String;
                    let description = dataDictionary["description"] as! String;
                    let coverDictionary = dataDictionary["cover"] as! Dictionary<String, Any>;
                    let cover = coverDictionary["url"] as! String;
                    let id = dataDictionary["minisiteId"] as! Int;
                    let deepLinkiOS = dataDictionary["deepLinkiOS"] as? String;
                    let beacon = dataDictionary["beacon"] as! Int;
                    var notificationImg:String?;
                    if let notification:Dictionary<String, Any> =
                        dataDictionary["notificationImage"] as? Dictionary<String, Any> {
                        notificationImg = notification["url"] as? String;
                    }
                    
                    var type = MinisiteType.ADVERTISEMENT;
                    
                    if let _:Dictionary<String, Any> = dataDictionary["coupon"] as? Dictionary<String, Any> {
                        type = MinisiteType.COUPON;
                    } else if deepLinkiOS != nil {
                        type = MinisiteType.DEEP_LINK;
                    } else if let _:Dictionary<String, Any> =
                        dataDictionary["voting"] as? Dictionary<String, Any> {
                        type = MinisiteType.VOTING;
                    } else if let _:Dictionary<String, Any> =
                        dataDictionary["polling"] as? Dictionary<String, Any> {
                        type = MinisiteType.POLLING;
                    }
                    
                    let viaMinisite: ViaMinisite = ViaMinisite(id: id, title: title, description: description, coverUrl: cover, url: url, type: type, deepLinkiOS: deepLinkiOS, notificationImg: notificationImg, beacon: beacon);
                    return viaMinisite;
                } catch {
                }
            } else {
            }
        }
        
        return nil;
    }
    
    func processCustomer(sdkToken: String, identifier: String, phone: String,
                         email: String, remark: String, os: String, authorizedZones: [ViaZone]?, isBroadcasting: Bool) -> ViaCustomer? {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        var argumentData:Dictionary<String, Any> = [
            "identifier": identifier,
            "phone" : phone,
            "email" : email,
            "remark" : remark,
            "os" : os,
            "broadcasting" : isBroadcasting
        ];
        
        if authorizedZones != nil {
            var zoneArray:[Dictionary<String, Int>] = [];
            
            for aZone in authorizedZones! {
                let zoneId = aZone.zoneId;
                
                let zoneDictionary:Dictionary<String,Int> = [
                    "zoneId" : zoneId
                ];
                
                zoneArray.append(zoneDictionary);
            }
            
            argumentData["authorizedZones"] = zoneArray;
        }
        
        let bodyData:Dictionary<String, Any> = [
            "field": "sdkProcessCustomer",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    let customerId = dataDictionary["customerId"] as! Int;
                    let uuid = dataDictionary["uuid"] as? String;
                    let major = dataDictionary["major"] as? Int;
                    let minor = dataDictionary["minor"] as? Int;
                    
                    let viaCustomer: ViaCustomer = ViaCustomer(customerId: customerId, identifier: identifier, email: email, phone: phone, remark: remark, os: os, uuid: uuid, major: major, minor:minor);
                    return viaCustomer;
                } catch {
                }
            } else {
            }
        }
        
        return nil;
    }
    
    func getAuthorizedZones(sdkToken: String, identifier: String) -> [Int] {
        var authorizedZones:[Int] = [];
        
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let argumentData:Dictionary<String, String> = [
            "identifier": identifier
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "sdkGetCustomer",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    
                    if let zoneArray = dataDictionary["authorizedZones"] as? [
                        Dictionary<String, Any>] {
                        
                        for zoneDictionary in zoneArray {
                            let zoneId = zoneDictionary["zoneId"] as! Int;
                            
                            authorizedZones.append(zoneId);
                        }
                    }
                } catch {
                }
            } else {
            }
        }
        
        return authorizedZones;
    }
    
    func checkin(sdkToken: String, customer: Int, time: String) -> Int? {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let inputData:Dictionary<String, Any> = [
            "customer": customer,
            "checkIn" : time
        ];
        
        let argumentData:Dictionary<String, Dictionary<String, Any>> = [
            "input" : inputData
        ]
        
        let bodyData:Dictionary<String, Any> = [
            "field": "createAttendance",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    
                    if let attendanceId = dataDictionary["attendanceId"] as? Int {
                        return attendanceId;
                    }
                } catch {
                }
            } else {
            }
        }
        
        return nil;
    }
    
    func checkout(sdkToken: String, attendanceId: Int, time: String) -> Bool {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let inputData:Dictionary<String, Any> = [
            "attendanceId": attendanceId,
            "checkOut" : time
        ];
        
        let argumentData:Dictionary<String, Dictionary<String, Any>> = [
            "input" : inputData
        ]
        
        let bodyData:Dictionary<String, Any> = [
            "field": "updateAttendance",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    
                    if (dataDictionary["attendanceId"] as? Int) != nil {
                        return true;
                    }
                } catch {
                }
            } else {
            }
        }
        
        return false;
    }
    
    func createProximityAlert(sdkToken: String, customer: Int, uuid: String, major : Int, minor: Int) -> Int? {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let inputData:Dictionary<String, Any> = [
            "customer": customer,
            "uuid" : uuid,
            "major" : major,
            "minor" : minor,
            "type" : "proximity"
        ];
        
        let argumentData:Dictionary<String, Dictionary<String, Any>> = [
            "input" : inputData
        ]
        
        let bodyData:Dictionary<String, Any> = [
            "field": "createCustomerAlert",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    
                    if let customerAlertId = dataDictionary["customerAlertId"] as? Int {
                        return customerAlertId;
                    }
                } catch {
                }
            } else {
            }
        }
        
        return nil;
    }
    
    func checkVoting(sdkToken: String, customer: Int, minisite: Int) -> Bool {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let argumentData:Dictionary<String, Int> = [
            "customer": customer,
            "minisite" : minisite
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "getVotingTokens",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let answers: [Dictionary<String, Any>] = try JSONSerialization.jsonObject(with: data!, options: []) as! [Dictionary<String, Any>];
                    return answers.count <= 0;
                } catch {
                }
            } else {
            }
        }
        
        return false;
    }
    
    func checkPolling(sdkToken: String, customer: Int, minisite: Int) -> Bool {
        
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let argumentData:Dictionary<String, Int> = [
            "customer": customer,
            "minisite" : minisite
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "getPollingTokens",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let answers: [Dictionary<String, Any>] = try JSONSerialization.jsonObject(with: data!, options: []) as! [Dictionary<String, Any>];
                    
                    return answers.count <= 0;
                } catch {
                }
            } else {
            }
        }
        
        return true;
    }
    
    func createSessionLog(sdkToken: String, customer: Int, minisite: Int, beacon: Int) -> Int {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let inputData:Dictionary<String, Int> = [
            "customer": customer,
            "minisite" : minisite,
            "beacon" : beacon
        ];
        
        let argumentData:Dictionary<String, Any> = [
            "input" : inputData
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "createSessionLog",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch { }
        
        let (data, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                do {
                    let dataDictionary: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>;
                    let logId = dataDictionary["sessionLogId"] as! Int;
                    
                    return logId;
                } catch {
                }
            } else {
            }
        }
        
        return 0;
    }
    
    func updateSessionLog(sdkToken: String, sessionLogId: Int) {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + SDK_PATH)!;
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let inputData:Dictionary<String, Any> = [
            "sessionLogId": sessionLogId,
            "ended" : true
        ];
        
        let argumentData:Dictionary<String, Any> = [
            "input": inputData
        ];
        
        let bodyData:Dictionary<String, Any> = [
            "field": "updateSessionLog",
            "arguments" : argumentData,
            "authorization" : "Bearer " + sdkToken
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: .prettyPrinted)
        } catch { }
        
        let (_, _, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
    }
    
    func coreTracking(apiKey: String, uuid: String, major: NSNumber, minor: NSNumber, identifier: String, phone: String, email: String, remark: String, distance: Double) {
        
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + CORE_TRACKING_PATH)!;
        
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let headers: Dictionary<String, String> = [
            ViaHeaderKey.API_KEY.rawValue: apiKey
        ];
        request.allHTTPHeaderFields = headers;
        
        let passData: Dictionary<String, Any> = [:];
        let requestData: Dictionary<String, Any> = [
            "uuid": uuid,
            "major" : major,
            "minor" : minor,
            "identifier" : identifier,
            "phone" : phone,
            "email" : email,
            "remark" : remark,
            "data" : passData,
            "distance" : distance
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (_, _, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
//                let (_, response, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
//                if let httpResponse = response as? HTTPURLResponse {
//                    if httpResponse.statusCode == 200 {
//                        print("success tracking");
//                    } else {
//                         print("fail tracking");
//                    }
//                }
        
    }
    
    func coreTrackingWithMQTT(apiKey: String, uuid: String, major: NSNumber, minor: NSNumber, identifier: String, phone: String, email: String, remark: String, distance: Double) {
        let sdkTokenURL: URL = URL(string: API_ENDPOINT + CORE_MQTT_TRACKING_PATH)!;
        
        var request = URLRequest(url: sdkTokenURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10);
        request.httpMethod = "POST";
        
        let headers: Dictionary<String, String> = [
            ViaHeaderKey.API_KEY.rawValue: apiKey
        ];
        request.allHTTPHeaderFields = headers;
        
        let requestData: Dictionary<String, Any> = [
            "uuid": uuid,
            "major" : major,
            "minor" : minor,
            "identifier" : identifier,
            "phone" : phone,
            "email" : email,
            "remark" : remark,
            "distance" : distance
        ];
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted)
        } catch {
            // Nothing...
        }
        
        let (_, _, _) = URLSession.shared.synchronousDataTask(urlrequest: request);
//                if let httpResponse = response as? HTTPURLResponse {
//                    if httpResponse.statusCode == 200 {
//                    } else {
//                        print("success tracking 3");
//                    }
//                }
    }
}

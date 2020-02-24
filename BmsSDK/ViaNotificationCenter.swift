//
//  ViaNotificationCenter.swift
//  iOsSDK
//
//  Created by Viatick on 20/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation
import UserNotifications
import NotificationCenter

protocol ViaNotificationDelegate {
    func viaNotificationCenter(center: ViaNotificationCenter, fire notification: String);
}

internal class ViaNotificationCenter: NSObject {
    var notificationCenter: Any?;
    let identifier = "ViaLocalNotification";
    
    func initiate() {
        if #available(iOS 10.0, *) {
            notificationCenter = UNUserNotificationCenter.current();
            let notificationOptions: UNAuthorizationOptions = [.alert, .sound, .badge];
            (notificationCenter as! UNUserNotificationCenter).getNotificationSettings { (settings) in
                if settings.authorizationStatus != .authorized {
                    (self.notificationCenter as! UNUserNotificationCenter).requestAuthorization(options: notificationOptions) { (granted, error) in
                        if !granted {
                            print("[VIATICK]: notification not alowed");
                        }
                    }
                }
            }
        } else {
            notificationCenter = UILocalNotification();
            let notificationSettings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil);
            UIApplication.shared.registerUserNotificationSettings(notificationSettings);
        }
    }
    
    func shootNotification(title: String, body: String, notificationImg: String?) {
        if #available(iOS 10.0, *) {
            let content: UNMutableNotificationContent = UNMutableNotificationContent();
            content.title = title;
            content.body = body;
            content.sound = UNNotificationSound.default;
            
            if notificationImg != nil {
                if let encodedImgStr = notificationImg!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    if let customURL = URL(string: encodedImgStr) {
                        let imageData = NSData(contentsOf: customURL);
                        
                        let now = UInt64(NSDate().timeIntervalSince1970 * 1000);
                        let identifier = String(now) + ".jpg";
                        
                        let attachement = UNNotificationAttachment.saveImageToDisk(fileIdentifier: identifier, data: imageData!, options: nil);
                        content.attachments = [ attachement ] as! [UNNotificationAttachment];
                    }
                }
            }
            
            let trigger: UNNotificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false);
            let request: UNNotificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger);
            (notificationCenter as! UNUserNotificationCenter).add(request) { (error) in
                if error != nil {
                    print("[VIATICK]: notification error");
                }
            }
        } else {
            (notificationCenter as! UILocalNotification).fireDate = NSDate(timeIntervalSinceNow: 0.1) as Date;
            (notificationCenter as! UILocalNotification).alertTitle = title;
            (notificationCenter as! UILocalNotification).alertBody = body;
            (notificationCenter as! UILocalNotification).soundName = UILocalNotificationDefaultSoundName;
            UIApplication.shared.scheduleLocalNotification(notificationCenter as! UILocalNotification);
        }
    }
}

extension UNNotificationAttachment {
    
    static func saveImageToDisk(fileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL?.appendingPathComponent(fileIdentifier)
            try data.write(to: fileURL!, options: [])
            let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL!, options: options)
            return attachment
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
}

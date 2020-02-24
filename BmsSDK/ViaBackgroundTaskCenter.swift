//
//  ViaBackgroundTaskCenter.swift
//  iOsSDK
//
//  Created by Viatick on 20/8/19.
//  Copyright © 2019 Viatick. All rights reserved.
//

import Foundation
import UIKit

internal class ViaBackgroundTaskCenter {
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid;
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask();
        }
        assert(backgroundTask != UIBackgroundTaskIdentifier.invalid);
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask);
        backgroundTask = UIBackgroundTaskIdentifier.invalid;
    }
}

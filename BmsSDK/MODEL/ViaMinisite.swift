//
//  ViaMinisite.swift
//  BLE MS SDK
//
//  Created by Bie Yaqing on 25/4/18.
//  Copyright © 2018 Bie Yaqing. All rights reserved.
//

import Foundation

internal struct ViaMinisite {
    var id: Int;
    var title: String;
    var description: String;
    var coverUrl: String;
    var url: String?;
    var type: MinisiteType;
    var deepLinkiOS : String?;
    var notificationImg : String?;
    var beacon : Int;
    var logId: Int?;
    init(id: Int, title: String, description: String, coverUrl: String, url: String?, type: MinisiteType, deepLinkiOS: String?, notificationImg: String?, beacon: Int) {
        self.id = id;
        self.title = title;
        self.description = description;
        self.coverUrl = coverUrl;
        self.url = url;
        self.type = type;
        self.deepLinkiOS = deepLinkiOS;
        self.notificationImg = notificationImg;
        self.beacon = beacon;
    }
    func same(viaMinisite: ViaMinisite) -> Bool {
        return self.id == viaMinisite.id;
    }
}

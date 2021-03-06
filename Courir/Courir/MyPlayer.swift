//
//  MyPlayer.swift
//  Courir
//
//  Created by Karen on 9/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

struct MyPlayer {
    var name: String? {
        return SettingsManager._instance.get(SettingsManager.nameKey) as? String
    }
    var deviceName: String {
        return UIDevice.currentDevice().name
    }
    var peerID: MCPeerID {
        return MCPeerID(displayName: name ?? deviceName)
    }
}
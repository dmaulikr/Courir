//
//  GameEvent.swift
//  Courir
//
//  Created by Karen on 20/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

enum GameEvent: Int {
    case GameDidStart = 0, GameDidEnd, ObstacleDidAppear, PlayerDidJump, PlayerDidDuck, PlayerDidCollide, PlayerLost, PlayerLeft
}
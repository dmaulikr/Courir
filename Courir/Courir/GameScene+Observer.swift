//
//  GameScene+Observer.swift
//  Courir
//
//  Created by Sebastian Quek on 3/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

extension GameScene: Observer {
    
    // ==============================================
    // MARK: Observe GameState
    // ==============================================
    
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        guard let _ = from as? GameState else {
            return
        }
        
        switch propertyName {
        case "gameIsOver":
            gameDidEnd()
        case "obstacles":
            handleChangesToObstacles()
        case "distance":
            updateScore()
        default:
            return
        }
    }
    
    private func gameDidEnd() {
        let gameOverData = [
            "eventRawValue": GameEvent.GameDidEnd.rawValue,
            "gameResult": gameState.scoreTracking,
            "ghostStore": gameState.ghostStore
        ]
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName("showEndGameMenu",
                                  object: self,
                                  userInfo: gameOverData as [NSObject : AnyObject])
    }
    
    private func handleChangesToObstacles() {
        
        // Handle newly added obstacles
        let addedObstacles = gameState.obstacles.filter {obstacles[$0.identifier] == nil}
        
        for obstacle in addedObstacles {
            obstacles[obstacle.identifier] = createObstacleNode(obstacle)
        }
        
        // Handle removed obstacles
        let obstacleIds = gameState.obstacles.map {$0.identifier}
        let removedObstacles = obstacles.filter {!obstacleIds.contains($0.0)}
        
        for (id, obstacleNode) in removedObstacles {
            obstacleNode.removeFromParent()
            obstacles.removeValueForKey(id)
        }
    }
    
    // Update the score
    private func updateScore() {
        scoreNode.setScore(gameState.distance)
    }
}

//
//  GameViewController.swift
//  Courir
//
//  Created by Karen on 25/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

class GameViewController: UIViewController {

    private var isMultiplayer: Bool {
        return gameSetupData.mode == GameMode.Multiplayer || gameSetupData.mode == GameMode.SpecialMultiplayer
    }

    private var gameSetupData: GameSetupData!

    var initialGhostStore: GhostStore?
    var gameEndGhostStore: GhostStore?
    
    private let portal = GameNetworkPortal._instance

    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var endGameMenu: GameEndView!
    @IBOutlet weak var endGameTable: UITableView!

    @IBOutlet weak var mainMenuButton: UIButton!
    @IBOutlet weak var saveRunButtton: UIButton!

    @IBOutlet weak var replayOrUnwindButton: UIButton!
    
    @IBOutlet weak var saveConfirmationLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.receiveEvent(_:)),
                                                         name: "showEndGameMenu", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.exitGame),
                                                         name: "exitGame", object: nil)
        setUpGameEndMenu()
        SKTextureAtlas.preloadTextureAtlases(textureAtlases, withCompletionHandler: presentGameScene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Start Game

    func setUpWith(data: GameSetupData) {
        gameSetupData = data
    }

    private func setUpGameEndMenu() {
        let title = isMultiplayer ? "back to room" : "play again"
        replayOrUnwindButton.setTitle(title, forState: .Normal)

        let menuButtons = [mainMenuButton, saveRunButtton, replayOrUnwindButton]
        for btn in menuButtons {
            let fadedColor = btn.currentTitleColor.colorWithAlphaComponent(0.2)
            btn.setTitleColor(fadedColor, forState: .Highlighted)
            btn.setTitleColor(fadedColor, forState: .Disabled)
        }

        endGameTable.dataSource = endGameMenu
        endGameTable.delegate = endGameMenu
        endGameMenu.hidden = true
        endGameMenu.alpha = 0
        endGameMenu.layer.cornerRadius = 10
    }

    private func presentGameScene() {
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.setUpWith(gameSetupData)
        gameScene.initialGhostStore = initialGhostStore
        let skView = self.view as! SKView!
        skView.ignoresSiblingOrder = true
        gameScene.scaleMode = .AspectFill
        skView.presentScene(gameScene)
    }

    func receiveEvent(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        guard let eventRawValue = userInfo["eventRawValue"] as? Int,
            gameResult = userInfo["gameResult"] as? [MCPeerID: Int],
            ghostStore = userInfo["ghostStore"] as? GhostStore else {
            return
        }
        
        var gameResultArray = [(peerID: MCPeerID, score: Int)]()
        gameEndGhostStore = ghostStore
        
        for (key, value) in gameResult {
            gameResultArray.append((peerID: key, score: value))
        }
        
        gameResultArray.sortInPlace({ $0.score > ($1.score) })
        
        if let event = GameEvent(rawValue: eventRawValue) {
            switch event {
            case .GameDidEnd:
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayGameEndMenu(gameResultArray)
                }
            default:
                break
            }
        }
    }

    // MARK: End Game

    func exitGame() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.isMultiplayer {
                self.performSegueWithIdentifier("unwindToMenuViaRoomView", sender: self)
            } else {
                self.performSegueWithIdentifier("unwindToSinglePlayerStart", sender: self)
            }
        })
    }
    
    private func displayGameEndMenu(gameResultArray: [(peerID: MCPeerID, score: Int)]) {
        endGameMenu.hidden = false
        endGameMenu.scoreSheet = gameResultArray
        endGameTable.reloadData()
        
        UIView.animateWithDuration(0.5) { () -> Void in
            self.endGameMenu.alpha = 1
        }
    }

    @IBAction func handleBackAction(sender: AnyObject) {
        if isMultiplayer {
            portal.disconnectFromRoom()
            performSegueWithIdentifier("unwindToMenuViaRoomView", sender: self)
        } else {
            performSegueWithIdentifier("unwindToMenuViaSinglePlayerStart", sender: self)
        }
    }
    
    @IBAction func saveRunButtonPressed(sender: AnyObject) {
        guard let ghostStore = gameEndGhostStore else {
            return
        }
        saveRunButtton.enabled = false
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            ghostStore.storeGhostData() { complete in
                dispatch_async(dispatch_get_main_queue()) {
                    self.showConfirmationLabel()
                }
            }
        }
    }
    
    private func showConfirmationLabel() {
        UIView.animateWithDuration(0.5,
            animations: {
                self.saveConfirmationLabel.alpha = 1
                self.saveConfirmationLabel.transform = CGAffineTransformMakeTranslation(0, -20)
            },
            completion: { finished in
                UIView.animateWithDuration(1,
                    delay: 5,
                    options: UIViewAnimationOptions.BeginFromCurrentState,
                    animations: {
                        self.saveConfirmationLabel.alpha = 0
                        self.saveConfirmationLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                    },
                    completion: nil
                )
            }
        )
    }
    
    @IBAction func replayOrUnwindButtonPressed(sender: AnyObject) {
        if isMultiplayer {
            portal.gameStateDelegate = nil
            performSegueWithIdentifier("unwindToRoomViewFromGameView", sender: self)
        } else {
            initialGhostStore = gameEndGhostStore
            setUpGameEndMenu()
            presentGameScene()
        }
    }
}

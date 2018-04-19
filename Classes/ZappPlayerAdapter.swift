//
//  ZappPlayerAdapter.swift
//  JWPlayer-Plugin-iOS
//
//  Created by Udi Lumnitz on 19/06/2017.
//  Copyright © 2017 Applicaster. All rights reserved.
//

import Foundation
import ZappPlugins
import ApplicasterSDK
import JWPlayer_iOS_SDK

///  No need to import JWPlayer here, we must use the briding header to #import
///  #import <JWPlayer-SDK/JWPlayerController.h>
///  TODO: setup podspec to include the bridging header or import JWPlayer-SDK/JWPlayerController.h directly

public class ZappPlayerAdapter: APPlugablePlayerBase {
    
    // MARK: - Properties
    
    var playerViewController: JWPlayerViewController?
    var currentPlayableItem: ZPPlayable?
    var currentPlayerState: ZPPlayerState = .undefined
    var isOnHold:Bool = false

    // MARK: - ZPPlayerProtocol
    
    /// Initialization of player instance view controller with item to play.
    ///
    /// - Parameter
    ///   - item: The instance ZPPlayable item.
    ///   - configurationJSON: A NSDictionary of the plugin custom configuraiton fields.
    /// - Returns: Creates an instance of the player view controller and, in this example, returns a ZappPlayerAdapter instance.
    public static func pluggablePlayerInit(playableItems items: [ZPPlayable]?, configurationJSON: NSDictionary?) -> ZPPlayerProtocol? {
        
        // configurationJSON example (not being used in the example):
        guard let playerKey = configurationJSON?["playerKey"] as? String else {
            APLoggerError("Failed to create customParam from the plugin configuration JSON.")
            return nil
        }
        
        JWPlayerController.setPlayerKey(playerKey)

        // creating the AVPlayer instance
        let instance = ZappPlayerAdapter()
        instance.playerViewController = JWPlayerViewController()
        instance.currentPlayableItem = items?.first
        return instance
    }
    
    /// Returns the view controller of current playable player instance.
    ///
    /// - Returns: Should return a playable view controller (for the specific instance).
    public override func pluggablePlayerViewController() -> UIViewController? {
        
         guard let item = currentPlayableItem else { return nil }
            
            let config: JWConfig = JWConfig()
            config.sources = [JWSource (file: item.contentVideoURLPath(), label: "", isDefault: true)]
        
            config.title = item.playableName() ?? ""
            config.controls = true  //default
            config.`repeat` = false   //default
            config.premiumSkin = JWPremiumSkinRoundster
            config.autostart = true
        
            let player = JWPlayerController(config: config)
            
            self.playerViewController?.player = player

            return self.playerViewController
    }
    
    /// Returns the playing asset.
    ///
    /// - Returns: Should return the playable stream url as NSURL.
    public func pluggablePlayerCurrentUrl() -> NSURL? {
        if let videoPath = currentPlayableItem?.contentVideoURLPath() {
            return NSURL(string: videoPath)
        }
        return nil
    }
    
    /// Returns the current playable item
    ///
    /// - Returns: Should return the current playable item of ZPPlayable type.
    public func pluggablePlayerCurrentPlayableItem() -> ZPPlayable? {
        return currentPlayableItem
    }
    
    // MARK: - Available only in Full screen mode
    
    /// Call this method to start playing the given playable. Because this is a full screen player after calling this method the app doesn't have control of it's flow.
    ///
    /// - Parameters:
    ///   - rootViewController: The app root view controller and it's topmostModal, in order to enable to present the player view controller.
    ///   - configuration: ZPPlayerConfiguration object, including few configurations for the player instance. For example, should the player start muted until tapped for the first time.
    public override func presentPlayerFullScreen(_ rootViewController: UIViewController, configuration: ZPPlayerConfiguration?) {
        self.presentPlayerFullScreen(rootViewController, configuration: configuration, completion: nil)
    }
   
    public override func presentPlayerFullScreen(_ rootViewController: UIViewController, configuration: ZPPlayerConfiguration?, completion: (() -> Void)?) {
        
        let animated : Bool = configuration?.animated ?? true
        let rootVC : UIViewController = rootViewController.topmostModal()
        
        //Present player
        if let playerVC = self.pluggablePlayerViewController() as? JWPlayerViewController {
            playerVC.isPresentedFullScreen = true
            rootVC.present(playerVC, animated:animated) {
                completion?()
            }
            playerVC.player.enterFullScreen()
        }
    }
    
    /// Start playing with configuration
    ///
    /// - Parameter configuration: ZPPlayerConfiguration object, including few configurations for the player instance. For example, should the player start muted until tapped for the first time.
    public override func pluggablePlayerPlay(_ configuration: ZPPlayerConfiguration?) {
        if self.currentPlayableItem?.isLive() == true {
            self.playVideo()
        }
        else {
            self.playVideo()
        }
    }
    
    /// Pauses active player
    public override func pluggablePlayerPause() {
        if let player = self.playerViewController?.player {
            player.pause()
            self.setPlayerState(.paused)
        }
    }
    
    /// Stop playing loaded item
    public override func pluggablePlayerStop() {
        if let player = self.playerViewController?.player {
            player.pause()
            self.setPlayerState(.stopped)
        }
    }
    
    /// Is player playing a video
    ///
    /// - Returns: Returns true if playing a video, otherwise false.
    public override func pluggablePlayerIsPlaying() -> Bool {
        var retValue = false
        if let player = self.playerViewController?.player {
            if player.playerState == "playing" {
                retValue = true
                self.setPlayerState(.playing)
            }
            else {
                retValue = false
                self.setPlayerState(.stopped)
            }
        }
        return retValue
    }
    
    // MARK: - Available only in Inline mode
    
    /// This func is called when a cell is requesting an inline player view to present inside.
    ///
    /// - Parameters:
    ///   - rootViewController: The cell view controller.
    ///   - container: The container view inside the cell.
    public override func pluggablePlayerAddInline(_ rootViewController: UIViewController, container : UIView) {

        if let playerVC = self.pluggablePlayerViewController() as? JWPlayerViewController {
            playerVC.isPresentedFullScreen = false
            rootViewController.addChildViewController(playerVC, to: container)
            playerVC.view.matchParent()
        }
    }
    
    /// This func is called when a cell is requesting to remove an inline player view that is already presented.
    public override func pluggablePlayerRemoveInline(){
        //get the container
        let container = self.pluggablePlayerViewController()?.view.superview
        super.pluggablePlayerRemoveInline()
        //remove temp view
        container?.removeFromSuperview()
    }
    
    // MARK: - Private
    
    public func playVideo() {
        if let player = self.playerViewController?.player {
            player.play()
            self.setPlayerState(.playing)
        }
    }
  
    open override func pluggablePlayerType() -> ZPPlayerType {
        return ZappPlayerAdapter.pluggablePlayerType()
    }
    
    open static func pluggablePlayerType() -> ZPPlayerType {
        return .undefined
    }
    
    func setPlayerState(_ state: ZPPlayerState) {
        if !self.isOnHold {
            self.currentPlayerState = state
        }
    }
    
    open func setOnHold(isOnHold: Bool) {
        self.isOnHold = isOnHold
        self.currentPlayerState = .onHold
    }
    
    open func playerState() -> ZPPlayerState {
        return self.currentPlayerState
    }
}

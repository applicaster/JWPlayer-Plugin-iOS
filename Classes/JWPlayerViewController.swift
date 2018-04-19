//
//  JWPlayerViewController.swift
//  JWPlayer-Plugin-iOS
//
//  Created by Roi Mulia on 10/1/17.
//  Copyright © 2017 Applicaster. All rights reserved.
//

import UIKit
import ZappPlugins
import ApplicasterSDK
import JWPlayer_iOS_SDK

final class JWPlayerViewController: UIViewController, JWPlayerDelegate {

    var isPresentedFullScreen = false
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if player.isInFullscreen {
            return [.landscapeLeft, .landscapeRight]
        }
        return .all
    }
    
    var player: JWPlayerController! {
        didSet {
            player.delegate = self
            
            player.view.frame = view.bounds
            player.view.autoresizingMask = [
                UIViewAutoresizing.flexibleBottomMargin,
                UIViewAutoresizing.flexibleHeight,
                UIViewAutoresizing.flexibleLeftMargin,
                UIViewAutoresizing.flexibleRightMargin,
                UIViewAutoresizing.flexibleTopMargin,
                UIViewAutoresizing.flexibleWidth]
           player.forceLandscapeOnFullScreen = true
           view.addSubview(player.view)
        }
    }
        
    func onFullscreenRequested(_ status: Bool) {
        if player.isInFullscreen && !status && isPresentedFullScreen {
            player.stop()
            dismiss(animated: true, completion: nil)
        }
    }
}

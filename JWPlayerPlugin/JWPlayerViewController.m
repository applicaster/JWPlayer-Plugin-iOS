//
//  JWPlayerViewController.m
//  JWPlayerPlugin
//
//  Created by Liviu Romascanu on 15/10/2018.
//  Copyright © 2018 Applicaster. All rights reserved.
//

#import "JWPlayerViewController.h"
#import "JWPlayer_iOS_SDK/JWPlayerController.h"
@import UIKit;

@interface JWPlayerViewController () <JWPlayerDelegate> {
    
}

@property (nonatomic, strong) JWPlayerController *player;
@property (nonatomic, strong) JWAdConfig *adConfig;

@end

@implementation JWPlayerViewController
@synthesize isPresentedFullScreen = _isPresentedFullScreen;
@synthesize player = _player;
@synthesize closeButton = _closeButton;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - public

- (void)setIsPresentedFullScreen:(BOOL)isPresentedFullScreen {
    _isPresentedFullScreen = isPresentedFullScreen;
    self.closeButton.hidden = !_isPresentedFullScreen;
}

- (UIButton *)closeButton {
    if (_closeButton) {
        return _closeButton;
    }
    
    UIButton *button = [UIButton new];
    button.titleLabel.font = [UIFont systemFontOfSize:25];
    [button setTitle:@"X" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    
    _closeButton = button;
    return button;
}

- (void)setupPlayerWithPlayableItem:(NSObject <ZPPlayable> *)playableItem
{
    JWConfig *config = [JWConfig new];
    config.sources = [NSArray arrayWithObject:[[JWSource alloc] initWithFile:[playableItem contentVideoURLPath]
                                                                       label:@""
                                                                   isDefault:YES]];
    
    config.title = playableItem.playableName;
    config.controls = YES;
    config.repeat = NO;
    config.autostart = YES;
    
    if (self.adConfig) {
        config.advertising = self.adConfig;
        self.adConfig = nil;
    }
    
    self.player = [[JWPlayerController alloc] initWithConfig:config];
}

- (void)setupPlayerAdvertisingWithConfiguration:(NSArray *)ads {
    JWAdConfig *adConfig = [self createBaseAdConfiguration];
    NSMutableArray *scheduleArray = [NSMutableArray new];
    
    if (ads != nil) {
        // ad configuration dictionary scheduling
        for (NSDictionary *adConfiguration in ads)
        {
            NSString *type = adConfiguration[@"type"];
            
            if ([type  isEqual: @"vmap"]) {
                // we are using a vmap configuration that includes scheduling inside one url
                adConfig.adVmap = adConfiguration[@"ad_url"];
                break;
            } else {
                // We need to schedule the ads
                JWAdBreak *adBreak = [self createAdBreakWithTag:adConfiguration[@"ad_url"] offset:adConfiguration[@"offset"]];
                
                if (adBreak) {
                    [scheduleArray addObject:adBreak];
                    
                    if ([type  isEqual: @"googleima"]) {
                        adConfig.client = JWAdClientGoogima;
                    } else {
                        adConfig.client = JWAdClientVast;
                    }
                }
            }
        }
    } else {
        // configure fallback ads according to configuration json
        if (self.isLive) {
            // Grab live ad fallbackconfiguration
            JWAdBreak *preroll = [self createAdBreakWithTag:self.configurationJSON[@"live_preroll_ad_url"]
                                                     offset:@"pre"];
            JWAdBreak *midRoll = [self createAdBreakWithTag:self.configurationJSON[@"live_midroll_ad_url"]
                                                     offset:self.configurationJSON[@"live_midroll_offset"]];
            
            if ([self.configurationJSON[@"live_ad_type"]  isEqual: @"googleima"]) {
                adConfig.client = JWAdClientGoogima;
            } else {
                adConfig.client = JWAdClientVast;
            }
            
            if (preroll != nil) {
                [scheduleArray addObject:preroll];
            }
            
            if (midRoll != nil) {
                [scheduleArray addObject:midRoll];
            }
        } else {
            // Grab live ad fallbackconfiguration
            JWAdBreak *preroll = [self createAdBreakWithTag:self.configurationJSON[@"vod_preroll_ad_url"]
                                                     offset:@"pre"];
            JWAdBreak *midRoll = [self createAdBreakWithTag:self.configurationJSON[@"vod_midroll_ad_url"]
                                                     offset:self.configurationJSON[@"vod_midroll_offset"]];
            
            if ([self.configurationJSON[@"vod_ad_type"]  isEqual: @"googleima"]) {
                adConfig.client = JWAdClientGoogima;
            } else {
                adConfig.client = JWAdClientVast;
            }
            
            if (preroll != nil) {
                [scheduleArray addObject:preroll];
            }
            
            if (midRoll != nil) {
                [scheduleArray addObject:midRoll];
            }
        }
    }
    
    // Set up the schedule if needed
    if ([scheduleArray count] > 0) {
        adConfig.schedule = scheduleArray;
    }
    
    if (self.player) {
        self.player.config.advertising = adConfig;
    } else {
        self.adConfig = adConfig;
    }
}

- (void)setupPlayerSubtitleTracksWithConfiguration:(NSArray *)subtitleTracks {
    if (self.player) {
        NSMutableArray *subtitleTracksArray = [NSMutableArray array];

        for (NSDictionary* currentSubtitleTrack in subtitleTracks)
        {
            NSDictionary *currentTrack;
            currentTrack = currentSubtitleTrack;
            NSString *subtitleTrackSource = currentTrack[@"src"];
            NSString *subtitleTrackLabel = currentTrack[@"label"];

            if (subtitleTrackSource.isNotEmpty && subtitleTrackLabel.isNotEmpty) {
                JWTrack *validSubtitleTrack = [JWTrack trackWithFile:subtitleTrackSource label:subtitleTrackLabel];

                [subtitleTracksArray addObject:validSubtitleTrack];
            }
        }

        self.player.config.tracks = subtitleTracksArray;
    }
}

- (void)play
{
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)stop
{
    
}

- (BOOL)isPlaying {
    if (self.player.state == JWPlayerStatePlaying) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - private

- (JWAdConfig *)createBaseAdConfiguration {
    JWAdConfig *adConfig = [JWAdConfig new];
    adConfig.adMessage = (self.configurationJSON[@"ad_message"] ? self.configurationJSON[@"ad_message"] : @"Ad duration countdown xx");
    adConfig.skipMessage = (self.configurationJSON[@"skip_message"] ? self.configurationJSON[@"skip_message"] : @"Skip in xx");
    adConfig.skipText = (self.configurationJSON[@"skip_text"] ? self.configurationJSON[@"skip_text"] : @"Move on");
    adConfig.skipOffset = (self.configurationJSON[@"skip_offset"] ? [self.configurationJSON[@"skip_offset"] intValue] : 3);
    
    return adConfig;
}

- (JWAdBreak *)createAdBreakWithTag:(NSString *)tag
                             offset:(NSString *)offset
{
    if ([tag isNotEmptyOrWhiteSpaces] && [offset isNotEmptyOrWhiteSpaces]) {
        return [JWAdBreak adBreakWithTag:tag offset:offset];
    } else {
        return nil;
    }
}

- (void)setPlayer:(JWPlayerController *)player {
    
    if (_player) {
        // If we already have a player - first dismiss it
        _player.delegate = nil;
        [_player.view removeFromSuperview];
        _player = nil;
    }
    
    player.delegate = self;
    player.view.frame = self.view.bounds;
    
    if (self.closeButton.allTargets.count == 0) {
        [self.closeButton addTarget:self
                             action:@selector(dismiss:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.closeButton removeFromSuperview];
    self.closeButton.alpha = 1.0;
    self.closeButton.hidden = !self.isPresentedFullScreen;
    [player.view addSubview:self.closeButton];
    self.closeButton.frame = CGRectMake(16.0, 36.0, 32.0 , 32.0);
    self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:player.view];
    [player.view matchParent];
    self.player.forceLandscapeOnFullScreen = NO;
    self.player.forceLandscapeOnFullScreen = NO;
    
    _player = player;
}

- (void)dismiss:(NSObject *)sender {
    if ([NSThread isMainThread]) {
        [self.player stop];
        UIViewController *vc = self.presentingViewController;
        
        if (vc) {
            [vc.view.window makeKeyAndVisible];
            [vc dismissViewControllerAnimated:YES completion:nil];
            [vc setNeedsStatusBarAppearanceUpdate];
            [UIViewController attemptRotationToDeviceOrientation];
        }
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismiss:sender];
        });
    }
}

- (void)adjustButtonAlpha:(BOOL)visible {
    self.closeButton.alpha = visible ? 1.0 : 0.0;
}

#pragma mark - JWPlayerDelegate

- (void)onComplete {
    if (self.isPresentedFullScreen) {
        [self dismiss:nil];
    }
}

- (void)onControlBarVisible:(JWEvent<JWControlsEvent> *)event {
    if ([NSThread isMainThread]) {
        [self adjustButtonAlpha:event.controls];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustButtonAlpha:event.controls];
        });
    }
}

@end

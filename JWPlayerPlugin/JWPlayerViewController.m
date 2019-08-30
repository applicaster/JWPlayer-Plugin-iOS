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
@synthesize player = _player;
@synthesize closeButton = _closeButton;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view. 
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pause)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];     // Fix for JP-5 task
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil]; // Fix for JP-5 task
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    BOOL lockLandscape = [self.configurationJSON[@"lock_landscape"] boolValue];
    return lockLandscape ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskAll;
}

#pragma mark - public

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
    //JW Config
    JWConfig *config = [JWConfig new];
    config.sources = [NSArray arrayWithObject:[[JWSource alloc] initWithFile:[playableItem contentVideoURLPath]
                                                                       label:@""
                                                                   isDefault:YES]];
    
    config.title = playableItem.playableName;
    config.controls = YES;
    config.repeat = NO;
    config.autostart = YES;
    
    //Skin Config - Currentlly used only to hide the full screen button.
    //This is a bug fix - When clicking full screen, the X button dissapears.
    //TODO - Find why the x button disapears and fix it. After that return the full screen button
    NSString *skinURL = self.configurationJSON[@"jw_skin_url"];
    if (skinURL != nil && [skinURL isNotEmptyOrWhiteSpaces]) {
        JWSkinStyling *skin = [JWSkinStyling new];
        skin.url = skinURL;
        config.skin = skin;
    }
    
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
                NSObject *rawOffset = adConfiguration[@"offset"];
                NSString *convertedOffset = nil;
                
                if ([rawOffset isKindOfClass:NSString.class]) {
                    NSString *offset = (NSString *)rawOffset;
                    if ([offset isEqualToString:@"preroll"]) {
                        convertedOffset = @"pre";
                    }
                    else if ([offset isEqualToString:@"postroll"]) {
                        convertedOffset = @"post";
                    }
                }
                else if ([rawOffset isKindOfClass:NSNumber.class]) {
                    convertedOffset = [(NSNumber *)rawOffset stringValue];
                }
                
                JWAdBreak *adBreak = [self createAdBreakWithTag:adConfiguration[@"ad_url"] offset:convertedOffset];
                
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
        
        if ([subtitleTracksArray count] > 0) {
            self.player.config.tracks = subtitleTracksArray;
        }
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
    
    // ---> Start for fix for JP-1 task <--- //
    [player.view addSubview:self.closeButton];
    self.closeButton.frame = CGRectZero;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *closeButtonValues = @{@"closeButton" : self.closeButton};
    NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(16)-[closeButton(32)]" options:0 metrics:nil views:closeButtonValues];
    NSArray *vertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(36)-[closeButton(32)]" options:0 metrics:nil views:closeButtonValues];
    
    [self.player.view addConstraints:vertical];
    [self.player.view addConstraints:horizontal];
    // ---> end of fix <--- //
    
    [self.view addSubview:player.view];
    [player.view matchParent];
    
    self.player.fullscreen                 = NO;        // Fix for JP-1 task - hide fullscreen control
    self.player.forceFullScreenOnLandscape = NO;
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

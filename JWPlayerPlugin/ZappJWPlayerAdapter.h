//
//  ZappPlayerAdapter.h
//  JWPlayerPlugin
//
//  Created by Liviu Romascanu on 15/10/2018.
//  Copyright © 2018 Applicaster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWPlayerViewController.h"

@import ZappPlugins;
@import ApplicasterSDK;

NS_ASSUME_NONNULL_BEGIN

@interface ZappJWPlayerAdapter : NSObject <ZPPlayerProtocol, ZPPluggableScreenProtocol>

@property (nonatomic, strong) JWPlayerViewController *playerViewController;
@property (nonatomic, strong) NSObject<ZPPlayable> *currentPlayableItem;
@property (nonatomic, assign) ZPPlayerState currentPlayerState;
@property (nonatomic, assign) BOOL isOnHold;
@property (nonatomic, strong) NSDictionary *configurationJSON;
@property (nonatomic, strong) NSArray<id<ZPPlayable>> *currentPlayableItems;

- (NSURL * _Nullable)pluggablePlayerCurrentUrl;

@end

NS_ASSUME_NONNULL_END

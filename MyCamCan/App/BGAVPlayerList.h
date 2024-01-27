//
//  BGAVPlayerList.h
//  MCC
//
//  Created by James Ajhar on 11/19/14.
//  Copyright (c) 2014 D9. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGAVPlayerList : NSObject

//-- singleton
+ (BGAVPlayerList *)sharedInstance;

- (void)addPlayer:(AVPlayer *)player;
- (void)removePlayer:(AVPlayer *)player;
- (void)removeAllPlayers;
- (AVPlayer *)playerForURL:(NSURL *)url;

- (void)cleanMemory:(NSNotification*)notification;

@end

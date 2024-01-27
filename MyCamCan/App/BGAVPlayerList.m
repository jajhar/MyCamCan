/**
 * BGAVPlayerList.h
 *  MCC
 *@author James Ajhar
 */

#import "BGAVPlayerList.h"


const NSUInteger kMaxCachedVideoPlayersCount = 1;  // The maximum number of players allowed in the active list


@interface BGAVPlayerList()

@property (strong, nonatomic) NSMutableArray *avplayerList;

@end

__strong static BGAVPlayerList *_instance = nil;

@implementation BGAVPlayerList


#pragma mark - Singleton


+ (BGAVPlayerList *)sharedInstance {
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        _instance = [[BGAVPlayerList alloc] init];
    });
    
    
    
    return _instance;
}


+ (id)alloc {
    @synchronized([BGAVPlayerList class]) {
        NSAssert(_instance == nil, @"Attempted to create second instance of Singleton");
        _instance = [super alloc];
        _instance.avplayerList = [NSMutableArray new];
        
        return _instance;
    }
    return nil;
}


#pragma mark - Implementation

/**
 *  Add an AVPlayer to the list of active players
 */
- (void)addPlayer:(AVPlayer *)player {
    
    // TODO: Make this based on available memory instead
    if(_avplayerList.count > kMaxCachedVideoPlayersCount) {
        [_avplayerList removeObjectAtIndex:0];
    }
    
    [_avplayerList addObject:player];
}

/**
 *  Remove an AVPlayer from the list of active players
 */
- (void)removePlayer:(AVPlayer *)player {
    [_avplayerList removeObject:player];
}

- (void)removeAllPlayers {
    [_avplayerList removeAllObjects];
}

- (void)cleanMemory:(NSNotification*)notification {
    NSLog(@"memory warning received - Cleaning AVPlayerList");
    
}

/**
 *  Returns an AVPlayer for a given video url if it exists. Otherwise returns nil
 */
- (AVPlayer *)playerForURL:(NSURL *)url {
    
    NSURL *assetUrl;
    for(AVPlayer *player in _avplayerList) {
        
        assetUrl = [(AVURLAsset *)player.currentItem.asset URL];
        
        if(assetUrl == url) {
            return player;
        }
    }
    
    return nil;
}




@end

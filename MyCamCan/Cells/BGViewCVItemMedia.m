//
//  BGViewCVItemMedia.m
//  Blog
//
//  Created by James Ajhar on 12/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGViewCVItemMedia.h"

#import "Media.h"

@interface BGViewCVItemMedia ()

@property (weak, nonatomic) IBOutlet UIImageView *mediaImageView;
@property (strong, nonatomic) Media *media;
@property (weak, nonatomic) IBOutlet UIImageView *playButton;

@end


@implementation BGViewCVItemMedia

- (void)commonInit {
    [super commonInit];
    
    [self.playButton setImage:[UIImage imageNamed:@"PlayBtn"]];
//    [self.playButton setTintColor:[UIColor whiteColor]];
}

- (void)setupWithMedia:(Media *)media {
    _media = media;
    
    [self.mediaImageView sd_setImageWithURL:_media.thumbUrl];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.mediaImageView setImage:nil];
}


@end

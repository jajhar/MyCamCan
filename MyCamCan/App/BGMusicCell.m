//
//  BGMusicCell.m
//  Blog
//
//  Created by James Ajhar on 7/23/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGMusicCell.h"
#import "MusicItem.h"


static __weak BGMusicCell *_lastSelectedCell = nil;


@interface BGMusicCell ()

@property (strong, nonatomic) IBOutlet UIImageView *albumImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end


@implementation BGMusicCell

- (void)commonInit {
    [super commonInit];
    
}

- (void)setMusicItem:(MusicItem *)musicItem {
    _musicItem = musicItem;
    
    [self setupDescriptionTextView];
    
    [self setAlbumImage];
}

- (void)setupDescriptionTextView {
    NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
    [titleAttributes setObject:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold] forKey:NSFontAttributeName];
    
    NSString *title = self.musicItem.title ? self.musicItem.title : @"";
    NSString *artist = self.musicItem.artist ? self.musicItem.artist : @"";

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title attributes:titleAttributes];
    
    
    NSAttributedString *attributedArtistName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", artist]
                                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                                                                                   NSForegroundColorAttributeName: [UIColor darkGrayColor]
                                                                                                   }];
    
    self.titleLabel.attributedText = attributedString;
    self.subtitleLabel.attributedText = attributedArtistName;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
    [titleAttributes setObject:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold] forKey:NSFontAttributeName];
    
    NSString *title = self.musicItem.title ? self.musicItem.title : @"";
    NSString *artist = self.musicItem.artist ? self.musicItem.artist : @"";
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title attributes:titleAttributes];
    NSAttributedString *attributedArtistName;
    
    if(selected ) {
        attributedArtistName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", artist]
                                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                                                                                       NSForegroundColorAttributeName: [UIColor whiteColor]
                                                                                                       }];
    } else {
        attributedArtistName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", artist]
                                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                                                                                       NSForegroundColorAttributeName: [UIColor darkGrayColor]
                                                                                                       }];
    }
    
    self.titleLabel.attributedText = attributedString;
    self.subtitleLabel.attributedText = attributedArtistName;
}

- (void)setAlbumImage {
    if(self.musicItem.artwork != nil) {
        [self.albumImageView setImage:self.musicItem.artwork];
    } else {
        [self.albumImageView sd_setImageWithURL:self.musicItem.imageURL placeholderImage:[UIImage imageNamed:@"generic-music"]];
    }
}

@end

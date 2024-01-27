//
//  FeedTableViewCell.m
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "FeedTableViewCell.h"
#import "PostContentPager.h"
#import "PostContentCell.h"

@interface FeedTableViewCell (){
    PostContentPager *_contentPager;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) Post *post;
@end

@implementation FeedTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self setupView];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setPost:(Post *)post{
    if(_post != post){
        _post = post;
        _contentPager = [post postContentPager];
    }
    [self setupView];
}


- (void)setupView {
   
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_contentPager elementsCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PostContentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PostContentCell" forIndexPath:indexPath];
    [cell updateWithPostContent:[_contentPager elementAtIndex:indexPath.row]];
    return cell;
}

@end

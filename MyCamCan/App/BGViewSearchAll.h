//
//  BGViewSearchAll.h
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGView.h"

@interface BGViewSearchAll : BGView

- (void)searchForContentWithKeyword:(NSString *)keyword;
- (void)showGlobalFeed;
- (void)showUserSearch;

@end

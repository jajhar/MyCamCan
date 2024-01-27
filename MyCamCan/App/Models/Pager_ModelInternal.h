//
//  Pager_ModelInternal.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/16/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "Pager.h"


@interface Pager ()

/**
 @return index of the <element> if it was present and deleted, otherwise - NSNotFound
 */
- (NSUInteger)deleteElement:(id)element;
- (NSUInteger)deleteElementAtIndex:(NSUInteger)index;

- (void)insertElement:(id)element atIndex:(NSUInteger)index;
- (void)addElement:(id)element;                                 // insert at the end

- (void)setupElements:(NSArray *)newElements;

@end
